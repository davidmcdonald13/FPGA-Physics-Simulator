// NOTE: clocking wizard can only create 161.905 MHz
// will this become an issue?
module top
   #(parameter SPRITES=4, DIMENSIONS=2, WIDTH=32)
   (input logic BTND, BTNU, //BTNL,
    input logic CLK100MHZ,
    input logic [15:0] SW,
    output logic VGA_HS, VGA_VS,
    output logic [3:0] VGA_R, VGA_B, VGA_G);
    
    logic clk_out1, locked;
    logic [62:0][62:0] sprite;
    logic [SPRITES-1:0][10:0] sprite_row;
    logic [SPRITES-1:0][11:0] sprite_col;
    logic [SPRITES-1:0][DIMENSIONS-1:0][WIDTH-1:0] init_locations, init_velos, locations, velos;
    logic [SPRITES-1:0][WIDTH/2-1:0] masses;
    logic [SPRITES-1:0][6:0] radii;
    logic collision;
    
    assign radii = {7'h1f, 7'h1f, 7'h1f, 7'h1f};
    assign masses = {16'h400, 16'h400, 16'h400, 16'h400};
    
    initial_selector #(SPRITES) is(SW, init_locations, init_velos);
   /* assign init_locations = {32'h0, 32'hff00_0000, 32'h0, 32'h100_0000};
    assign init_velos = 'd0;*/
        
    clk_wiz_0 clk(.CLK100MHZ(CLK100MHZ), .clk_out1(clk_out1), .reset(BTND), .locked(locked));

    VGA_driver #(SPRITES) vga(.clock_162(clk_out1), .rst(BTND), .HSYNC(VGA_HS),
                        .VSYNC(VGA_VS), .RED(VGA_R), .GREEN(VGA_G), .BLUE(VGA_B),
                        .sprite(sprite), .sprite_row(sprite_row), .sprite_col(sprite_col));
                   
    sprite_generator sg(.sprite(sprite));
        
    physics_engine #(SPRITES, WIDTH, DIMENSIONS) pe(clk_out1, ~BTND, BTNU, init_locations, init_velos,
        masses, radii, locations, collision);
        
    locations_to_centers #(SPRITES, WIDTH) ltc(locations, sprite_row, sprite_col);
    
endmodule: top

module initial_selector
   #(SPRITES=4)
   (input logic [15:0] sel,
    output logic [SPRITES-1:0][1:0][31:0] loc, vel);
    
    always_comb begin
        loc = 'd0;
        vel = 'd0;
        case (sel)
            'd0: begin
                loc[0] = {32'h0100_0000, 32'h0100_0000};
                loc[1] = {32'hff00_0000, 32'hff00_0000};
                loc[2] = {32'h0100_0000, 32'hff00_0000};
                loc[3] = {32'hff00_0000, 32'h0100_0000};
            end
            'd1: begin
                loc[0] = {32'h0100_0000, 32'h0100_0000};
                loc[1] = {32'hff00_0000, 32'hff00_0000};
                loc[2] = {32'h0100_0000, 32'hff00_0000};
                loc[3] = {32'hff00_0000, 32'h0100_0000};
                vel[0] = {32'h0010_0000, 32'h0};
                vel[1] = {32'hfff0_0000, 32'h0};
                vel[2] = {32'h0010_0000, 32'h0};
                vel[3] = {32'hfff0_0000, 32'h0};
             end
            /*'d1: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
            end
            'd2: begin
                loc[0] = {32'h0100_0000, 32'h0};
                loc[1] = {32'hff00_0000, 32'h0};
            end
            'd3: begin
                loc[0] = {32'h0100_0000, 32'h0};
                loc[1] = {32'hff00_0000, 32'h0};
                vel[0] = {32'h0000_4000, 32'h0};
                vel[1] = {32'hffff_c000, 32'h0};
            end
            'd4: begin
                loc[0] = {32'h0100_0000, 32'h0};
                loc[1] = {32'hff00_0000, 32'h0};
                vel[0] = {32'h0000_1000, 32'h0};
                vel[1] = {32'hffff_f000, 32'h0};
            end
            'd5: begin
                loc[0] = {32'h0100_0000, 32'h0};
                loc[1] = {32'hff00_0000, 32'h0};
                vel[0] = {32'h0000_8000, 32'h0};
                vel[1] = {32'hffff_8000, 32'h0};
            end
            'd6: begin
                loc[0] = {32'h0100_0000, 32'h0};
                loc[1] = {32'hff00_0000, 32'h0};
                vel[0] = {32'h0001_0000, 32'h0};
                vel[1] = {32'hffff_0000, 32'h0};
            end
            'd7: begin
                loc[0] = {32'h0, 32'h0320_0000};
                loc[1] = {32'h0, 32'hfce0_0000};
            end
            'd8: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0000_1000, 32'h0};
                vel[1] = {32'h0000_1000, 32'h0};
            end
            'd9: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0001_0000, 32'h0};
                vel[1] = {32'h0001_0000, 32'h0};
            end
            'd10: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0000_1000, 32'h0};
                vel[1] = {32'hffff_f000, 32'h0};
            end
            'd11: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0000_0100, 32'h0};
                vel[1] = {32'hffff_ff00, 32'h0};
            end
            'd12: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0000_0400, 32'h0};
                vel[1] = {32'hffff_fc00, 32'h0};
            end
            'd13: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0010_0000, 32'h0};
                vel[1] = {32'hfff0_0000, 32'h0};
            end
            'd14: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0100_0000, 32'h0};
                vel[1] = {32'hff00_0000, 32'h0};
            end
            'd15: begin
                loc[0] = {32'h0100_0000, 32'h0100_0000};
                loc[1] = {32'hff00_0000, 32'hff00_0000};
                vel[0] = {32'h0001_0000, 32'h0};
                vel[1] = {32'hffff_0000, 32'h0};
            end
            'd16: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0001_0000, 32'h0};
                vel[1] = {32'h0001_0000, 32'h0};
            end
            'd17: begin
                loc[0] = {32'h0, 32'h0100_0000};
                loc[1] = {32'h0, 32'hff00_0000};
                vel[0] = {32'h0004_0000, 32'h0};
                vel[1] = {32'h0004_0000, 32'h0};
            end*/
        endcase
    end
endmodule: initial_selector