// NOTE: this module assumes WIDTH/2 bits decimal and WIDTH/2 bits int
// NOTE: this module assumes that WIDTH is at least 22
module location_to_pixels
   #(parameter WIDTH=32)
   (input logic [1:0][WIDTH-1:0] dimensions,
    output logic [11:0] col,
    output logic [10:0] row);

    logic [WIDTH/2-1:0] row_int, rounded_row_int, col_int, rounded_col_int;

    assign col_int = dimensions[0][WIDTH-1:WIDTH/2];
    assign row_int = dimensions[1][WIDTH-1:WIDTH/2];

    always_comb begin
        // TODO implement rounding
        rounded_col_int = col_int;// + dimensions[0][WIDTH/2-1];
        rounded_row_int = row_int;// + dimensions[1][WIDTH/2-1];
        rounded_col_int[11] = rounded_col_int[WIDTH/2-1];
        rounded_row_int[10] = rounded_row_int[WIDTH/2-1];
        col = rounded_col_int[11:0] + 12'd800;
        row = -rounded_row_int[10:0] + 11'd600;
    end
endmodule: location_to_pixels

module locations_to_centers
   #(parameter SPRITES=9, WIDTH=32)
   (input logic [SPRITES-1:0][1:0][WIDTH-1:0] locations,
    output logic [SPRITES-1:0][10:0] rows,
    output logic [SPRITES-1:0][11:0] cols);
    
    genvar i;
    generate
        for (i = 0; i < SPRITES; i++) begin: f1
            location_to_pixels #(WIDTH) ltp(locations[i], cols[i], rows[i]);
        end
    endgenerate
endmodule: locations_to_centers
/*module location_to_pixels_testbench();

    logic [31:0] row_in, col_in;
    logic [1:0][31:0] dimensions;
    logic [11:0] col_out;
    logic [10:0] row_out;

    location_to_pixels ltp(dimensions, col_out, row_out);

    assign dimensions = {col_in, row_in};

    initial begin
        $monitor($time, "row_in=0x%h, col_in=0x%h, row_out=%d, col_out=%d", row_in, col_in, row_out, col_out);
        for (row_in = 'd0; row_in < ~32'd0; row_in++) begin
            for (col_in = 'd0; col_in < ~32'd0; col_in++) begin
                #1;
            end
        end
    end

endmodule: location_to_pixels_testbench
*/