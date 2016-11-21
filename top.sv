// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   #(parameter SPRITES=1, DIMENSIONS=2, WIDTH=32)
   (input logic BTND, BTNU,
    input logic CLK100MHZ,
    input logic [5:0] SW,
    output logic [15:0] LED,
    output logic VGA_HS, VGA_VS,
    output logic [3:0] VGA_R, VGA_B, VGA_G);
    
    logic clk_out1, locked;
    logic [126:0][126:0] sprite;
    logic [SPRITES-1:0][10:0] sprite_row;
    logic [SPRITES-1:0][11:0] sprite_col;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos, locations;
    logic [SPRITES-1:0][WIDTH-1:0] masses;
    logic [SPRITES-1:0][6:0] radii;
    logic [WIDTH-1:0] number_of_sprites;
    
    assign init_locations = {32'h0, 32'h0};//{32'hfe00_0000, 32'hfe00_0000, 32'hfe00_0000, 32'h0, 32'h0, 32'hfe00_0000};//{32'h100_0000, 32'h100_0000, 32'h0, 32'hff00_0000, 32'hff00_0000, 32'h100_0000};
    assign init_velos[0][0] = 'hfffc_0000;//'hffff_0000;
    assign init_velos[0][1] = 'hfffc_0000;//'hffff_0000;
    //assign init_velos[2:1] = 'd0;
    assign masses[0] = 'h40000;
    //assign masses[1] = 'h0000;
    //assign masses[2] = 'h0000;
    assign radii = 'd0;
    
    assign LED = number_of_sprites[31:16];
    
//    assign sprite_row = {11'd400, 11'd500, 11'd900,  11'd1200};
//    assign sprite_col = {12'd400, 12'd600, 12'd1300, 12'd1600};
    
    clk_wiz_0 clk(.CLK100MHZ(CLK100MHZ), .clk_out1(clk_out1), .reset(BTND), .locked(locked));

    VGA_driver #(SPRITES) vga(.clock_162(clk_out1), .rst(BTND), .HSYNC(VGA_HS),
                        .VSYNC(VGA_VS), .RED(VGA_R), .GREEN(VGA_G), .BLUE(VGA_B),
                        .sprite(sprite), .sprite_row(sprite_row), .sprite_col(sprite_col));
                   
    sprite_generator sg(.radius(6'h3f), .sprite(sprite));
    
  /*  module physics_engine
       #(parameter SPRITES=9, WIDTH=32, DIMENSIONS=2)
       (input logic clk, rst_l, data_ready,
        input logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos,
        input logic [SPRITES-1:0][WIDTH-1:0] masses,
        input logic [SPRITES-1:0][6:0] radii,
        output logic [SPRITES-1:0] locations);*/
        
    physics_engine #(SPRITES, WIDTH, DIMENSIONS) pe(clk_out1, ~BTND, BTNU, init_locations, init_velos,
        masses, radii, locations, number_of_sprites);
        
    locations_to_centers #(SPRITES, WIDTH) ltc(locations, sprite_row, sprite_col);
    
  /*  gen_inputs gi(clk_out1, ~BTND, sprite_col[0], sprite_row[0]);
    
    move_hor mh(clk_out1, ~BTND, sprite_col[1], sprite_row[1]);*/

endmodule: top

module move_hor(
    input logic clk, rst_l,
    output logic [11:0] col,
    output logic [10:0] row);
    
    logic [21:0] counter, next_counter;
    logic [11:0] next_col;
    
    assign row = 11'd300;
    
    always_comb begin
        if (counter >= 'd2699999)
            next_counter = 0;
         else
            next_counter = counter + 1;
        if (counter == 'd0)
            next_col = col + 1;
        else
            next_col = col;
    end
    
    
    always_ff @(posedge clk) begin
        if (~rst_l) begin
            col <= 'd0;
            counter <= 'd0;
        end
        else begin
            counter <= next_counter;
            col <= next_col;
        end
    end
    
endmodule: move_hor