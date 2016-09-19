// 1600 x 1200 monitor
// Standards taken from tinyvga.com/vga-timing/1600x1200@60Hz

module VGA_driver
   (input logic clock_162, rst,
    output logic [3:0] RED, GREEN, BLUE,
    output logic HSYNC, VSYNC);

    logic [10:0] row, next_row;
    logic [11:0] col, next_col;
    logic [21:0] counter, next_counter;
    logic        hor_visible, vert_visible;
    logic        HS_l, VS_l;

    range_check #(12) hsync(col, 12'd64, 12'd255, HS_l);
    range_check #(11) vsync(row, 11'd1, 11'd3, VS_l);

    range_check #(12) hv(col, 12'd256, 12'd1855, hor_visible);
    range_check #(11) vv(col, 11'd4, 11'd1203, vert_visible);

    assign HSYNC = ~HS_l;
    assign VSYNC = ~VS_l;
    assign RED = 4'd0;
    assign GREEN = 4'd0;
    assign BLUE = (hor_visible && vert_visible) ? 4'hF : 4'h0;

    always_comb begin
        if (counter == 22'd2_700_000) // 2160 * 1250
            next_counter = 0;
        else
            next_counter = counter + 1;

        if (counter % 2160 == 22'd0) begin
            next_row = next_row + 1;
            next_col = 0;
        end
        else begin
            next_row = next_row;
            next_col = next_col + 1;
        end
    end

    always_ff @(posedge clock_162) begin
        // NEXYS 4 buttons are HIGH when pushed
        if (rst) begin
            row <= 0;
            col <= 0;
            counter <= 0;
        end
        else begin
            row <= next_row;
            col <= next_col;
            counter <= next_counter;
        end
    end

endmodule: VGA_driver
