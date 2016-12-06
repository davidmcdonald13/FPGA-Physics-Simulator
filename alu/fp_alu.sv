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

module fp_mul
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
    
endmodule: fp_mul

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
