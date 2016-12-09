`default_nettype none 

module fp_add
    #(parameter n=32)
    (input logic [n-1:0] a, b,
     output logic [n-1:0] result);
     
     assign result = a+b;
     
 endmodule: fp_add
 
 module fp_sub
    #(parameter n=32)
    (input logic [n-1:0] a, b,
    output logic [n-1:0] result);
    
    assign result = a + (~b+1);
    
endmodule: fp_sub

/*module fp_mul
    #(parameter n=32)
    (input logic [n-1:0] a, b,
    output logic [n-1:0] result);
    
    logic [2*n-1:0] big_buf;
    logic [n-1:0] abs_a, abs_b;
    logic s;
    
    always_comb begin
        s = a[n-1] ^ b[n-1];
        abs_a = a[n-1] ? ~a + 1 : a;
        abs_b = b[n-1] ? ~b + 1 : b;
        big_buf = abs_a * abs_b;
        result = s ? (1 + ~big_buf[3*n/2-1:n/2]) : big_buf[3*n/2-1:n/2];
    end
    
endmodule: fp_mul*/

module fp_div
    #(parameter n=64, q=32)
    (input logic [n-1:0] a, b,
    output logic [n-1:0] result);
    
    logic s;
    logic [n-1:0] abs_b;
    logic [n-1:0] big_buf;
    logic [n+q-1:0] abs_a;
    
    always_comb begin
        s = a[n-1] ^ b[n-1];
        abs_a = a[n-1] ? (~a + 1) << q : a << q;
        abs_b = b[n-1] ? ~b + 1 : b;
        big_buf = abs_a / abs_b;
        result = s ? ~big_buf[n-1:0] + 1 : big_buf[n-1:0];
    end
    
endmodule: fp_div

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

endmodule: big_subtractor

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

/*module multiplier
   #(parameter WIDTH=32)
   (input logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out);

    fp_mul #(WIDTH) mul(a, b, out);

endmodule: multiplier*/

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

module truncate
   #(parameter BIG=48, TARGET=32, CHOP=16)
   (input logic [BIG-1:0] full,
    output logic [TARGET-1:0] trunc);

    logic [BIG-1:0] abs_full;
    logic [TARGET-1:0] abs_trunc;

    always_comb begin
        abs_full = full[BIG-1] ? ~full + 1 : full;
        abs_trunc = {1'b0, abs_full[TARGET+CHOP-2:CHOP]};
        trunc = full[BIG-1] ? ~abs_trunc + 1 : abs_trunc;
    end
endmodule: truncate

/*module unsigned_divider
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
endmodule: unsigned_divider*/