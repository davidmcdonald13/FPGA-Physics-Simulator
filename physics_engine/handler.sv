module collision_handler
   #(SPRITES=9, DIMENSIONS=2, WIDTH=32)
   (input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] locations, velos,
    input logic clk, rst_l,
    output logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] new_velos,
    output logic collision);

    logic [$clog2(SPRITES)-1:0] sprite_i, sprite_j, next_sprite_i, next_sprite_j;
    logic [15:0] counter, next_counter;
    logic [DIMENSIONS-1:0][WIDTH-1:0] dv;
    logic [SPRITES-1:0][SPRITES-1:0] collision_matrix;
    logic [SPRITES-1:0] collision_vector;
    logic [SPRITES-1:0][SPRITES-1:0][2*WIDTH+2:0] d_squared_matrix;
    logic [SPRITES-1:0][SPRITES-1:0][WIDTH:0] xdiff_matrix, ydiff_matrix;
    
    assign collision = collision_vector[0] | collision_vector[1] | collision_vector[2] | collision_vector[3];
    genvar i, j;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            always_comb begin
                collision_vector[i] = collision_matrix[i][0] | collision_matrix[i][1] | collision_matrix[i][2] | collision_matrix[i][3];
                collision_matrix[i][i] = 0;
                d_squared_matrix[i][i] = 'd0;
                xdiff_matrix[i][i] = 'd0;
                ydiff_matrix[i][i] = 'd0;
                /*if (collision_vector[i]) begin
                    new_velos[i][1] = ~velos[i][1] + 1;
                    new_velos[i][0] = ~velos[i][0] + 1;
                end
                else begin
                    new_velos[i][1] = velos[i][1];
                    new_velos[i][0] = velos[i][0];
                end*/
            end
            for (j = i + 1; j < SPRITES; j++) begin: f2
                collision_detector #(WIDTH) cd(locations[i], locations[j],
                    collision_matrix[i][j], d_squared_matrix[i][j], xdiff_matrix[i][j], ydiff_matrix[i][j]);
                always_comb begin
                    collision_matrix[j][i] = collision_matrix[i][j];
                    d_squared_matrix[j][i] = d_squared_matrix[i][j];
                    xdiff_matrix[j][i] = xdiff_matrix[i][j];
                    ydiff_matrix[j][i] = ydiff_matrix[i][j];
                end
            end
        end
    endgenerate
                    
                    
    
//    vel_diff #(WIDTH) vd(locations[sprite_i], locations[sprite_j], velos[sprite_i], velos[sprite_j],
//        d_squared_matrix[sprite_i][sprite_j], xdiff_matrix[sprite_i][sprite_j], ydiff_matrix[sprite_i][sprite_j], dv);

    always_comb begin
        next_counter = counter + 'd1;
        next_sprite_i = sprite_i;
        next_sprite_j = sprite_j;
        if (counter == 16'hffff) begin
            next_sprite_j = sprite_j + 'd1;
            if (sprite_j == 'd0)
                next_sprite_i = sprite_i + 'd1;
        end
    end


    always_ff @(posedge clk) begin
        if (~rst_l) begin
            sprite_i <= 'd0;
            sprite_j <= 'd0;
            counter <= 'd0;
            new_velos <= velos;
        end
        else begin
            sprite_i <= next_sprite_i;
            sprite_j <= next_sprite_j;
            counter <= next_counter;
            if (counter == 16'hffff) begin
                if (collision_matrix[sprite_i][sprite_j]) begin
                    new_velos[sprite_i] <= velos[sprite_j];
                    new_velos[sprite_j] <= velos[sprite_i];                   
                end
                if (~collision_vector[sprite_i]) begin
                    new_velos[sprite_i][1] <= velos[sprite_i][1];
                    new_velos[sprite_i][0] <= velos[sprite_i][0];
                end
                if (~collision_vector[sprite_j]) begin
                    new_velos[sprite_j][1] <= velos[sprite_j][1];
                    new_velos[sprite_j][0] <= velos[sprite_j][0];
                end
            end
        end
                    
            
            
            
            
//            if ((counter == 16'hffff) && (sprite_i != sprite_j) && collision) begin
//                new_velos[sprite_i][1] <= velos[sprite_i][1] - dv[1];
//                new_velos[sprite_i][0] <= velos[sprite_i][0] - dv[0];
//                new_velos[sprite_j][1] <= velos[sprite_j][1] + dv[1];
//                new_velos[sprite_j][0] <= velos[sprite_j][0] + dv[0];
//            end
//        end
    end

endmodule: collision_handler

module collision_detector
   #(parameter WIDTH=32)
   (input logic [1:0][WIDTH-1:0] loca, locb,
    output logic collision,
    output logic [2*WIDTH+2:0] d_squared,
    output logic [WIDTH:0] xdiff, ydiff);
    
    logic [2*WIDTH+1:0] x_squared, y_squared;
    
    big_subtractor #(WIDTH) sub1(loca[1], locb[1], xdiff),
                                sub2(loca[0], locb[0], ydiff);
    big_multiplier #(WIDTH+1) bm1(xdiff, xdiff, x_squared),
                            bm2(ydiff, ydiff, y_squared);

    big_adder #(2*WIDTH+2) ba1(x_squared, y_squared, d_squared);

    assign collision = d_squared[2*WIDTH+2:WIDTH] <= 34'd3844;
    
endmodule: collision_detector

/*module vel_diff
    #(parameter WIDTH=32)
   (input logic [1:0][WIDTH-1:0] loca, locb, vela, velb,
    input logic [2*WIDTH+2:0] d_squared,
    input logic [WIDTH:0] xdiff, ydiff,
    output logic [1:0][31:0] dv);

    logic [WIDTH-1:0] x_trunc, y_trunc;
    logic [WIDTH:0] x_vel_diff, y_vel_diff;
    logic [2*WIDTH+1:0] dot_x, dot_y, x_squared, y_squared;
    logic [2*WIDTH+2:0] dot_product;
    logic [2*WIDTH+2:0] quot;
    logic [3*WIDTH+3:0] x_prod, y_prod;


    big_subtractor #(WIDTH) sub3(vela[1], velb[1], x_vel_diff),
                            sub4(vela[0], velb[0], y_vel_diff);

    big_multiplier #(WIDTH+1) dot1(xdiff, x_vel_diff, dot_x),
                              dot2(ydiff, y_vel_diff, dot_y);

    big_adder #(2*WIDTH+2) dp(dot_x, dot_y, dot_product);
    
    divider #(2*WIDTH+3) q(dot_product, d_squared, quot);
    
    com_add_multiplier #(WIDTH+1, 2*WIDTH+3) x(xdiff, quot, x_prod),
                                             y(ydiff, quot, y_prod);

                         
     truncate #(3*WIDTH+4, WIDTH, WIDTH) x_chop(x_prod, x_trunc),
                                         y_chop(y_prod, y_trunc);

//    subtractor #(WIDTH) ix(velocities[sprite_i][1], x_trunc, calc_velo_i[1]),
//                        iy(velocities[sprite_i][0], y_trunc, calc_velo_i[0]);
//    adder      #(WIDTH) jx(velocities[sprite_j][1], x_trunc, calc_velo_j[1]),
//                        jy(velocities[sprite_j][0], y_trunc, calc_velo_j[0]);
        assign dv[1] = x_trunc;
        assign dv[0] = y_trunc;
endmodule: vel_diff
*/
