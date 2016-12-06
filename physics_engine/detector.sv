// NOTE: this assumes 2 dimensions, will not work with 3D
/*module detector
   #(WIDTH=32)
   (input logic [1:0][WIDTH-1:0] loc_A, loc_B,
    input logic [6:0] radius_A, radius_B,
    input logic [WIDTH-1:0] mass_A, mass_B,
    output logic collision);

    logic has_collided;
    logic [7:0] radius_total;
    logic [15:0] r_squared;
    logic [WIDTH:0] xdiff, ydiff;
    logic [2*WIDTH+1:0] x_squared, y_squared;
    logic [2*WIDTH+2:0] d_squared;
    logic [WIDTH-14:0] zeros = 'd0;

    big_adder #(7) ba(radius_A, radius_B, radius_total);
    unsigned_multiplier #(8) bm(radius_total, radius_total, r_squared);

    big_subtractor #(WIDTH) sub1(loc_A[1], loc_B[1], xdiff),
                        sub2(loc_A[0], loc_B[0], ydiff);

    big_multiplier #(WIDTH+1) bm1(xdiff, xdiff, x_squared),
                            bm2(ydiff, ydiff, y_squared);

    big_adder #(2*WIDTH+2) ba1(x_squared, y_squared, d_squared);

    assign has_collided = d_squared[2*WIDTH+2:WIDTH] <= {zeros, r_squared};
    assign collision = mass_A && mass_B && has_collided;


endmodule: detector

module big_subtractor
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH:0] result);

    logic [WIDTH:0] a_buf, b_buf;

    always_comb begin
        a_buf = {a[WIDTH-1], a};
        b_buf = {b[WIDTH-1], b};
        result = a_buf + ~b_buf + 1;
    end

endmodule: big_subtractor*/

module big_adder
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH:0] result);

    assign result = a + b;

endmodule: big_adder

module big_multiplier
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [2*WIDTH-1:0] result);

    logic s;
    logic [WIDTH-1:0] abs_a, abs_b;
    logic [2*WIDTH-1:0] buffer;

    always_comb begin
        s = a[WIDTH-1] ^ b[WIDTH-1];
        abs_a = a[WIDTH-1] ? ~a + 1 : a;
        abs_b = b[WIDTH-1] ? ~b + 1 : b;
        buffer = abs_a * abs_b;
        result = s ? ~buffer + 1 : buffer;
    end

endmodule: big_multiplier

/*module unsigned_multiplier
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [2*WIDTH-1:0] result);

    assign result = a * b;

endmodule: unsigned_multiplier*/
