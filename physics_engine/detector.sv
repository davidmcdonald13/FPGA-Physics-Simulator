/*module collision_detector
    #(parameter SPRITES=9, DIMENSIONS=2, WIDTH=32)
    (input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations,
        velocities,
    input logic [SPRITES-1:0][6:0] radii,
    input logic clk, rst_l,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] new_velocities,
    output logic collision);

    logic [SPRITES-1:0][SPRITES-1:0]               collision_matrix;
    logic [SPRITES-1:0][SPRITES-1:0][2*WIDTH+2:0] d_squared;
    logic [SPRITES-1:0][SPRITES-1:0][WIDTH:0] xdiff, ydiff;
    assign collision = |collision_matrix;
    logic [SPRITES-1:0] collision_vector;
    
//    collision_handler #(SPRITES, DIMENSIONS, WIDTH) ch(d_squared, xdiff, ydiff, locations, velocities, collision_matrix,
//            clk, rst_l, new_velocities, collision);
    
    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            assign collision_vector[i] = collision_matrix[0] | collision_matrix[1] | collision_matrix[2] | collision_matrix[3];
            assign collision_matrix[i][i] = 0;
            assign d_squared[i][i] = 'd0;
            assign xdiff[i][i] = 'd0;
            assign ydiff[i][i] = 'd0;
            for (j = 0; j < DIMENSIONS; j++) begin: f3
                assign new_velocities[i][j] = collision_vector[i] ? ~velocities[i][j] + 1 : velocities[i][j];
            end
            for (j = i + 1; j < SPRITES; j++) begin: f2
                detector #(WIDTH) d(locations[i], locations[j],
                                    radii[i], radii[j],
                                    d_squared[i][j],
                                    xdiff[i][j], ydiff[i][j],
                                    collision_matrix[i][j]);
                assign collision_matrix[j][i] = collision_matrix[i][j];
                assign d_squared[j][i] = d_squared[i][j];
                assign xdiff[j][i] = xdiff[i][j];
                assign ydiff[j][i] = xdiff[i][j];
            end
        end
    endgenerate

endmodule: collision_detector

// NOTE: this assumes 2 dimensions, will not work with 3D
module detector
   #(WIDTH=32)
   (input logic [1:0][WIDTH-1:0] loc_A, loc_B,
    input logic [6:0] radius_A, radius_B,
    output logic [2*WIDTH+2:0] d_squared,
    output logic [WIDTH:0] xdiff, ydiff,
    output logic collision);
    
    logic [7:0] radius_total;
    logic [15:0] r_squared;
    //logic [WIDTH:0] xdiff, ydiff;
    logic [2*WIDTH+1:0] x_squared, y_squared;
    logic [WIDTH-14:0] zeros = 'd0;

//    big_adder #(7) ba(radius_A, radius_B, radius_total);
//    unsigned_multiplier #(8) bm(radius_total, radius_total, r_squared);

    big_subtractor #(WIDTH) sub1(loc_A[1], loc_B[1], xdiff),
                        sub2(loc_A[0], loc_B[0], ydiff);

    big_multiplier #(WIDTH+1) bm1(xdiff, xdiff, x_squared),
                            bm2(ydiff, ydiff, y_squared);

    big_adder #(2*WIDTH+2) ba1(x_squared, y_squared, d_squared);

    assign collision = d_squared[2*WIDTH+2:WIDTH] <= 35'd3844;//{zeros, r_squared};


endmodule: detector*/
