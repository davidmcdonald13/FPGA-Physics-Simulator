module physics_engine
   #(parameter SPRITES=9, WIDTH=32, DIMENSIONS=2)
   (input logic clk_162, rst_l, data_ready,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos,
    input logic [SPRITES-1:0][WIDTH-1:0] masses,
    input logic [SPRITES-1:0][6:0] radii,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    output logic [WIDTH-1:0] spritessss);

    logic [DIMENSIONS-1:0][SPRITES-1:0][WIDTH-1:0] COM_weights;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations_reg, velo_reg, next_locations, next_velos,
                                                   calc_locations, calc_velos;

    logic [21:0] counter, next_counter;
    logic [WIDTH-1:0] actual_sprites;
    
    assign spritessss = velo_reg[0][0];

    COM_calc #(SPRITES, DIMENSIONS, WIDTH) com(masses, locations_reg, COM_weights);

    sprite_counter #(SPRITES, WIDTH) sc(masses, actual_sprites);

    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            for (j = 0; j < DIMENSIONS; j++) begin: f2
                calc #(SPRITES, WIDTH, i) c(COM_weights[j], masses, locations_reg[i][j],
                    velo_reg[i][j], actual_sprites, calc_locations[i][j],
                    calc_velos[i][j]);
            end
        end
    endgenerate

    // TODO implement collision detection
    assign locations = locations_reg;

    always_comb begin
        next_counter = (counter == 22'd2_699_999) ? 'd0 : counter + 'd1;
        if (counter == 'd0) begin
            next_locations = calc_locations;
            next_velos = calc_velos;
        end
        else begin
            next_locations = locations_reg;
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
            locations_reg <= 'd0;
            velo_reg <= 'd0;
            counter <= 'd0;
        end
        else begin
            counter <= next_counter;
            locations_reg <= next_locations;
            velo_reg <= next_velos;

        end
    end

endmodule: physics_engine

module sprite_counter
   #(parameter SPRITES=9, WIDTH=32)
   (input logic [SPRITES-1:0][WIDTH-1:0] masses,
    output logic [WIDTH-1:0] count);

    logic [SPRITES-1:0] booleans;

    genvar i;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            assign booleans[i] = (masses[i] != 'd0);
        end
    endgenerate
    
    always_comb begin
        count = 'd0;
        foreach(booleans[idx]) begin
            count += booleans[idx];
        end
    end
        
endmodule: sprite_counter

module COM_calc
   #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
   (input logic [SPRITES-1:0][WIDTH-1:0] masses,
    input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
    output logic [DIMENSIONS-1:0][SPRITES-1:0][WIDTH-1:0] weights);

    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            for (j = 0; j < DIMENSIONS; j++) begin: f2
                multiplier #(WIDTH) m(masses[i], locations[i][j], weights[j][i]);
            end
        end
    endgenerate

endmodule: COM_calc

// NOTE: the value of SPRITES *must* be (1 + 2^n)
module calc
   #(parameter SPRITES=9, WIDTH=32, SPRITE_INDEX=0)
   (input logic [SPRITES-1:0][WIDTH-1:0] weights,
    input logic [SPRITES-1:0][WIDTH-1:0] masses,
    input logic [WIDTH-1:0] location, velo, actual_sprites,
    output logic [WIDTH-1:0] new_location, new_velo);

    logic [WIDTH-1:0] com_sum, total_mass, com, r, r_squared, a, dv, dx, dt, shifted_com;
    logic [WIDTH-1:0] actual_a, calculated_loc, calculated_velo;

    masked_adder_tree #(SPRITES, WIDTH, SPRITE_INDEX) big_com(weights, com_sum),
                                                      real_mass(masses, total_mass);

    //divider #(WIDTH) com_calc(com_sum, actual_sprites, com);
    subtractor #(WIDTH) r_calc(com, location, r);
    multiplier #(WIDTH) r_squarer(r, r, r_squared);
    divider #(WIDTH) accel(total_mass, r_squared, a);
    multiplier #(WIDTH) vel_change(actual_a, dt, dv);
    adder #(WIDTH) vel_calc(dv, velo, calculated_velo);
    multiplier #(WIDTH) loc_change(calculated_velo, dt, dx);
    adder #(WIDTH) loc_calc(dx, location, calculated_loc);

    assign new_location = (masses[SPRITE_INDEX] == 0) ? location : calculated_loc;
    assign new_velo = (masses[SPRITE_INDEX] == 0) ? velo : calculated_velo;
    assign actual_a = r_squared ? (r[WIDTH-1] ? ~a + 1 : a) : 'd0;
    assign shifted_com = com_sum >> 1;//($clog2(SPRITES-1));//TODO change this with SPRITES
    assign com = {com_sum[WIDTH-1], shifted_com[WIDTH-2:0]};
    assign dt = 'h444;// NOTE: this is the best approximation of 1/60 with 16 bits fraction

endmodule: calc

module masked_adder_tree
   #(parameter SPRITES=9, WIDTH=32, SPRITE_INDEX=0)
   (input logic [SPRITES-1:0][WIDTH-1:0] values,
    output logic [WIDTH-1:0] sum);

    logic [SPRITES-2:0][WIDTH-1:0] input_values;

    genvar i;
    generate
        for (i = 0; i < SPRITES-1; i++) begin: f1
            assign input_values[i] = (i < SPRITE_INDEX) ? values[i] : values[i+1];
        end
    endgenerate

    adder_tree #(SPRITES-1, WIDTH) tree(input_values, sum);
endmodule: masked_adder_tree

// NOTE: parameter INPUTS *must* be a power of 2
module adder_tree
   #(parameter INPUTS=8, WIDTH=32)
   (input logic [INPUTS-1:0][WIDTH-1:0] inputs,
    output logic [WIDTH-1:0] sum);

    genvar i;
    generate
        if (INPUTS == 1)
            assign sum = inputs[0];
        else if (INPUTS == 2)
            adder #(WIDTH) result(inputs[0], inputs[1], sum);
        else begin
            logic [INPUTS-2:0][WIDTH-1:0] intermediate;
            for (i = 0; i < INPUTS/2; i++) begin: f1
                adder #(WIDTH) top_row(inputs[2*i], inputs[2*i+1], intermediate[i]);
            end
            for (i = 0; i < INPUTS-2; i++) begin: f2
                adder #(WIDTH) inter(intermediate[2*i], intermediate[2*i+1], intermediate[i + INPUTS/2]);
            end
            assign sum = intermediate[INPUTS-2];
        end
    endgenerate

endmodule: adder_tree

module multiplier
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_alu #(WIDTH) mul(a, b, 2'b10, out);

endmodule: multiplier

module adder
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_alu #(WIDTH) add(a, b, 2'b00, out);

endmodule: adder

module subtractor
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_alu #(WIDTH) sub(a, b, 2'b01, out);

endmodule: subtractor

module divider
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_alu #(WIDTH) div(a, b, 2'b11, out);

endmodule: divider
