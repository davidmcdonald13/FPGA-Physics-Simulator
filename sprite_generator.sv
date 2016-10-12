module sprite_generator
   (input  logic [5:0] radius,
    output logic [126:0][126:0] sprite);

    genvar i, j;
    generate
        for (i = 0; i < 127; i++) begin: f1
            for (j = 0; j < 127; j++) begin: f2
                rad_check rc((i - 63) * (i - 63) + (j - 63) * (j - 63),
                          radius, sprite[i][j]);
            end
        end
    endgenerate

endmodule: sprite_generator

module rad_check
   (input logic [31:0] location_radius,
    input logic [5:0] radius,
    output logic in_circle);

    logic [31:0] rad_squared;

    always_comb begin
        rad_squared = radius * radius;
        in_circle = location_radius < rad_squared;
    end

endmodule: rad_check

/*module testbench();

    logic [2:0] radius;
    logic [14:0][14:0] this_sprite;

    sprite_generator sg(radius, this_sprite);

    initial begin
        $monitor($time,, "radius = %h\nsprite[0] = %b\nsprite[1] = %b\nsprite[2] = %b\nsprite[3] = %b\nsprite[4] = %b\nsprite[5] = %b\nsprite[6] = %b\nsprite[7] = %b\nsprite[8] = %b\nsprite[9] = %b\nsprite[10]= %b\nsprite[11]= %b\nsprite[12]= %b\nsprite[13]= %b\nsprite[14]= %b", radius, this_sprite[0], this_sprite[1], this_sprite[2], this_sprite[3], this_sprite[4], this_sprite[5], this_sprite[6], this_sprite[7], this_sprite[8], this_sprite[9], this_sprite[10], this_sprite[11], this_sprite[12], this_sprite[13], this_sprite[14]
        );
        for (radius = 3'd0; radius < 3'h7; radius++) begin
            #10;
        end
        #10 $finish;
    end
endmodule: testbench*/

/*
2 7
3 15
4 31
5 63
*/
