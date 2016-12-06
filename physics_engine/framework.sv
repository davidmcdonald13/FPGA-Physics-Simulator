module physics_engine
   #(parameter SPRITES=9, WIDTH=32, DIMENSIONS=2)
   (input logic clk_162, rst_l, data_ready,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos,
    input logic [SPRITES-1:0][WIDTH/2-1:0] masses,
    input logic [SPRITES-1:0][6:0] radii,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    input logic btn);

    logic [DIMENSIONS-1:0][SPRITES-1:0][3*WIDTH/2-1:0] COM_weights;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] velo_reg, next_locations, next_velos,
                                                   calc_locations, calc_velos;

    logic [21:0] counter, next_counter;

    COM_calc #(SPRITES, DIMENSIONS, WIDTH) com(masses, locations, COM_weights);

    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            for (j = 0; j < DIMENSIONS; j++) begin: f2
                calc #(SPRITES, WIDTH, i) c(COM_weights[j], masses, locations[i][j],
                    velo_reg[i][j], /*actual_sprites,*/ calc_locations[i][j],
                    calc_velos[i][j]);
            end
        end
    endgenerate

    // TODO implement collision detection

    always_comb begin
        next_counter = (counter == 22'd2_699_999) ? 'd0 : counter + 'd1;
        if (counter == 22'd2_699_999) begin
            next_locations = calc_locations;
            next_velos = calc_velos;
        end
        else begin
            next_locations = locations;
            next_velos = velo_reg;
        end
        if (data_ready) begin
            next_counter = 'd0;
            next_locations = init_locations;
            next_velos = init_velos;
        end
    end

    always_ff @(posedge clk_162) begin
        if (~rst_l) begin
            locations <= 'd0;
            velo_reg <= 'd0;
            counter <= 'd0;
        end
        else begin
            counter <= next_counter;
            if (counter == 22'd2_699_999) begin
                locations <= calc_locations;//next_locations;
                velo_reg <= calc_velos;//next_velos;
            end
            else if (data_ready) begin
                locations <= init_locations;
                velo_reg <= init_velos;
            end
        end
    end

endmodule: physics_engine

module COM_calc
   #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
   (input logic [SPRITES-1:0][WIDTH/2-1:0] masses,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    output logic [DIMENSIONS-1:0][SPRITES-1:0][3*WIDTH/2-1:0] weights);

    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            for (j = 0; j < DIMENSIONS; j++) begin: f2
                com_add_multiplier #(WIDTH/2, WIDTH) m(masses[i], locations[i][j], weights[j][i]);
            end
        end
    endgenerate

endmodule: COM_calc

module calc
   #(parameter SPRITES=9, WIDTH=32, SPRITE_INDEX=0)
   (input logic [SPRITES-1:0][3*WIDTH/2-1:0] weights,
    input logic [SPRITES-1:0][WIDTH/2-1:0] masses,
    input logic [WIDTH-1:0] location, velo,
    output logic [WIDTH-1:0] new_location, new_velo);

    logic [3*WIDTH/2-1:0] r_squared, a, actual_a, dv, calculated_velo, dx, calculated_loc;
    logic [3*WIDTH/2-1:0] com_sum, com, r, abs_r;
    logic [WIDTH/2-1:0] total_mass, locextend, veloextend;
    logic [WIDTH-1:0] trunc_velo, trunc_loc;

    assign locextend = location[WIDTH-1] ? ~'d0 : 'd0;
    assign veloextend = velo[WIDTH-1] ? ~'d0 : 'd0;

    generate
        if (SPRITE_INDEX == 0) begin
            assign com_sum = weights[1];
            assign total_mass = masses[1];
        end
        else begin
            assign com_sum = weights[0];
            assign total_mass = masses[0];
        end
    endgenerate

    divider #(3*WIDTH/2, WIDTH/2) com_calc(com_sum, {16'd0, total_mass, 16'd0}, com);
    subtractor #(3*WIDTH/2) r_calc(com, {locextend, location}, r);
    divider #(3*WIDTH/2, WIDTH/2) accel({16'd0, total_mass, 16'd0}, abs_r, a);
    assign dv = $signed(actual_a) >>> 6;
   
    adder #(3*WIDTH/2) vel_calc(dv, {veloextend, velo}, calculated_velo);
    
    assign dx = $signed(calculated_velo) >>> 6;
   
    adder #(3*WIDTH/2) loc_calc(dx, {locextend, location}, calculated_loc);
    
    truncate #(3*WIDTH/2, WIDTH) l(calculated_loc, trunc_loc),
                                 v(calculated_velo, trunc_velo);

    assign new_location = (masses[SPRITE_INDEX] == 0) ? location : calculated_loc[WIDTH-1:0];
    assign new_velo = (masses[SPRITE_INDEX] == 0) ? velo : calculated_velo[WIDTH-1:0];
    assign actual_a = r ? (r[3*WIDTH/2-1] ? ~a + 1 : a) : 'd0;
    assign abs_r = r[3*WIDTH/2-1] ? ~r + 1 : r;

endmodule: calc

module truncate
   #(parameter BIG=48, TARGET=32)
   (input logic [BIG-1:0] full,
    output logic [TARGET-1:0] trunc);
    
    logic [BIG-1:0] abs_full;
    logic [TARGET-1:0] abs_trunc;
    
    always_comb begin
        abs_full = full[BIG-1] ? ~full + 1 : full;
        abs_trunc = {1'b0, abs_full[TARGET-2:0]};
        trunc = full[BIG-1] ? ~abs_trunc + 1 : abs_trunc;
    end
endmodule: truncate

module com_add_multiplier
   #(parameter SIZE_ONE=32, SIZE_TWO=32)
   (input logic [SIZE_ONE-1:0] a,
    input logic [SIZE_TWO-1:0] b,
    output logic [SIZE_ONE+SIZE_TWO-1:0] result);
    
    logic [SIZE_TWO-1:0] abs_b;
    logic [SIZE_ONE+SIZE_TWO-1:0] buffer;

    assign abs_b = b[SIZE_TWO-1] ? ~b + 1 : b;
    assign buffer = a * abs_b;
    assign result = b[SIZE_TWO-1] ? ~buffer + 1 : buffer;
    
endmodule: com_add_multiplier

module multiplier
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_mul #(WIDTH) mul(a, b, out);

endmodule: multiplier

module adder
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_add #(WIDTH) add(a, b, out);

endmodule: adder

module subtractor
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_sub #(WIDTH) sub(a, b, out);

endmodule: subtractor

module divider
   #(parameter WIDTH=32, Q=16)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_div #(WIDTH, Q) div(a, b, out);

endmodule: divider

module unsigned_divider
    #(parameter n=64, q=32)
    (input logic [n-1:0] a, b,
    output logic [n-1:0] result);
    
    logic [n-1:0] big_buf;
    logic [n+q-1:0] buf_a;
    
    always_comb begin
        buf_a = a << q;
        big_buf = buf_a / b;
        result = big_buf[n-1:0];
    end
endmodule: unsigned_divider
