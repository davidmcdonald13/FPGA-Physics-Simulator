module physics_engine
   #(parameter SPRITES=9, WIDTH=32, DIMENSIONS=2)
   (input logic clk_162, rst_l, data_ready,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos,
    input logic [SPRITES-1:0][WIDTH/2-1:0] masses,
    input logic [SPRITES-1:0][6:0] radii,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    output logic collision);

    logic collision_out;
    logic [DIMENSIONS-1:0][3*WIDTH/2-1:0] COM_sum;
    logic [DIMENSIONS-1:0][SPRITES-1:0][3*WIDTH/2-1:0] COM_weights;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] velo_reg, next_locations, next_velos,
                                   calc_locations, calc_velos, col_velos;
    logic [DIMENSIONS-1:0][3*WIDTH-1:0] distances_squared;
    logic [DIMENSIONS-1:0][WIDTH-1:0] curr_calc_locations, curr_calc_velos;

    logic [21:0] counter, next_counter;
    logic [15:0] small_counter, next_small_counter;
    logic [$clog2(SPRITES)-1:0] sprite_index, next_sprite_index;

    COM_calc #(SPRITES, DIMENSIONS, WIDTH) com(/*masses,*/ locations, COM_weights);
    
    assign COM_sum[0] = COM_weights[0][0] + COM_weights[0][1] + COM_weights[0][2] + COM_weights[0][3];
    assign COM_sum[1] = COM_weights[1][0] + COM_weights[1][1] + COM_weights[1][2] + COM_weights[1][3];

   /* genvar i;
    generate
        for (i = 0; i < DIMENSIONS; i++) begin: f1
            logic dist_index;
            assign dist_index = (i == 0) ? 1 : 0;
            calc #(SPRITES, WIDTH) c(COM_weights[i], masses, locations[sprite_index][i],
                velo_reg[sprite_index][i], distances_squared[dist_index],
                sprite_index, curr_calc_locations[i],
                curr_calc_velos[i], distances_squared[i]);
        end
    endgenerate*/
    calc #(SPRITES, WIDTH) c0(COM_sum[0], COM_weights[0], masses, locations[sprite_index][0], velo_reg[sprite_index][0],
        distances_squared[1], sprite_index, curr_calc_locations[0], curr_calc_velos[0], distances_squared[0]);
        
    calc #(SPRITES, WIDTH) c1(COM_sum[1], COM_weights[1], masses, locations[sprite_index][1], velo_reg[sprite_index][1],
        distances_squared[0], sprite_index, curr_calc_locations[1], curr_calc_velos[1], distances_squared[1]);
        
    collision_handler #(SPRITES, DIMENSIONS, WIDTH) ch(calc_locations, calc_velos, clk_162, rst_l,
        col_velos, collision_out);

//    collision_detector #(SPRITES, DIMENSIONS, WIDTH) cd(calc_locations, calc_velos, radii,
//           clk_162, rst_l, col_velos, collision_out);
    //       assign col_velos = calc_velos;
           
  // assign collision_out = 0;
           
   // assign collision = collision_out;
           
    assign next_counter = (counter == 22'd2_699_999) ? 'd0 : counter + 'd1;
    assign next_small_counter = small_counter + 'd1;

    always_comb begin
        next_sprite_index = sprite_index;
        if (small_counter == 16'hffff) begin
            next_sprite_index = sprite_index + 'd1;
            if (sprite_index == SPRITES-1)
                next_sprite_index = 'd0;
        end
    end

    always_ff @(posedge clk_162) begin
        collision <= 0;
        if (~rst_l) begin
            locations <= 'd0;
            velo_reg <= 'd0;
            counter <= 'd0;
            small_counter <= 'd0;
            sprite_index <= 'd0;
            calc_locations <= 'd0;
            calc_velos <= 'd0;
        end
        else begin
            counter <= next_counter;
            small_counter <= next_small_counter;
            sprite_index <= next_sprite_index;
            if (counter == 22'd2_699_999) begin
                collision <= collision_out;
                locations <= calc_locations;
                velo_reg <= col_velos;
                small_counter <= 'd0;
                sprite_index <= 'd0;
            end
            else if (data_ready) begin
                counter <= 'd0;
                small_counter <= 'd0;
                locations <= init_locations;
                velo_reg <= init_velos;
                sprite_index <= 'd0;
            end
            else if (small_counter == 16'hffff) begin
                calc_locations[sprite_index] <= curr_calc_locations;
                calc_velos[sprite_index] <= curr_calc_velos;
            end
        end
    end

endmodule: physics_engine

module COM_calc
   #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
   (/*input logic [SPRITES-1:0][WIDTH/2-1:0] masses,*/
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    output logic [DIMENSIONS-1:0][SPRITES-1:0][3*WIDTH/2-1:0] weights);

    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            for (j = 0; j < DIMENSIONS; j++) begin: f2
                com_add_multiplier #(WIDTH/2, WIDTH) m(16'h400, locations[i][j], weights[j][i]);
            end
        end
    endgenerate

endmodule: COM_calc

module calc
   #(parameter SPRITES=9, WIDTH=32)
   (input logic [3*WIDTH/2-1:0] weights_sum,
    input logic [SPRITES-1:0][3*WIDTH/2-1:0] weights,
    input logic [SPRITES-1:0][WIDTH/2-1:0] masses,
    input logic [WIDTH-1:0] location, velo,
    input logic [3*WIDTH-1:0] ry_squared,
    input logic [1:0] sprite_index,
    output logic [WIDTH-1:0] new_location, new_velo,
    output logic [3*WIDTH-1:0] r_squared);


    logic [3*WIDTH-1:0] top, a, distance;
    logic [3*WIDTH/2-1:0] com_sum, com, r, abs_r;
    logic [WIDTH/2-1:0] total_mass, half_zero;
    logic [3*WIDTH/2-1:0] locextend, veloextend;
    logic [WIDTH-1:0] trunc_velo, trunc_loc;
    logic [5*WIDTH/2-1:0] actual_a, dv, calculated_velo, dx, calculated_loc;

    assign locextend = location[WIDTH-1] ? ~'d0 : 'd0;
    assign veloextend = velo[WIDTH-1] ? ~'d0 : 'd0;
    assign half_zero = 'd0;
    assign distance = r_squared + ry_squared;

    assign com_sum = weights_sum - weights[sprite_index];
    assign total_mass = 16'hc00;//masses[sprite_index];

    divider #(3*WIDTH/2, WIDTH/2) com_calc(com_sum, {16'd0, total_mass, 16'd0}, com);
    subtractor #(3*WIDTH/2) r_calc(com, {locextend[WIDTH/2-1:0], location}, r);
    big_multiplier #(3*WIDTH/2) r_squarer(abs_r, abs_r, r_squared);
    big_multiplier #(3*WIDTH/2) top_calc(r, {16'd0, total_mass, 16'd0}, top);
    divider #(3*WIDTH, WIDTH) accel1(top, distance, a);
    assign dv = $signed(actual_a) >>> 6;

    adder #(5*WIDTH/2) vel_calc(dv, {veloextend, velo}, calculated_velo);

    assign dx = $signed(calculated_velo) >>> 6;

    adder #(5*WIDTH/2) loc_calc(dx, {locextend, location}, calculated_loc);

    truncate #(5*WIDTH/2, WIDTH, 0) l(calculated_loc, trunc_loc),
                                        v(calculated_velo, trunc_velo);

    assign new_location = trunc_loc;
    assign new_velo = trunc_velo;
    assign actual_a = distance ? a[3*WIDTH-1:WIDTH/2] : 'd0;
    assign abs_r = r[3*WIDTH/2-1] ? ~r + 1 : r;

endmodule: calc
