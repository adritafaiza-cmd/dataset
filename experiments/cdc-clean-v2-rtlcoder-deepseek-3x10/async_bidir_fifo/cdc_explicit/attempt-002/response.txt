Here is the complete Verilog code for the bidirectional asynchronous FIFO module:

```
module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

    // Local parameters
    localparam FSIZE = 1 << ASIZE;
    localparam FSIZE_M1 = FSIZE - 1;

    // Internal signals
    reg [DSIZE-1:0] a_mem [FSIZE-1:0];
    reg [DSIZE-1:0] b_mem [FSIZE-1:0];
    reg [ASIZE-1:0] a_wptr;
    reg [ASIZE-1:0] a_rptr;
    reg [ASIZE-1:0] b_wptr;
    reg [ASIZE-1:0] b_rptr;
    reg [ASIZE:0] a_count;
    reg [ASIZE:0] b_count;
    wire [ASIZE-1:0] a_wptr_next;
    wire [ASIZE-1:0] a_rptr_next;
    wire [ASIZE-1:0] b_wptr_next;
    wire [ASIZE-1:0] b_rptr_next;
    wire [ASIZE:0] a_count_next;
    wire [ASIZE:0] b_count_next;
    wire a_full_next;
    wire a_afull_next;
    wire a_empty_next;
    wire a_aempty_next;
    wire b_full_next;
    wire b_afull_next;
    wire b_empty_next;
    wire b_aempty_next;
    wire [DSIZE-1:0] a_rdata_next;
    wire [DSIZE-1:0] b_rdata_next;

    // Write pointer
    always @(posedge a_clk or negedge a_rst_n) begin
        if (~a_rst_n) begin
            a_wptr <= {ASIZE{1'b0}};
        end else if (a_winc) begin
            a_wptr <= a_wptr_next;
        end
    end

    // Read pointer
    always @(posedge b_clk or negedge b_rst_n) begin
        if (~b_rst_n) begin
            b_rptr <= {ASIZE{1'b0}};
        end else if (b_rinc) begin
            b_rptr <= b_rptr_next;
        end
    end

    // Write pointer
    always @(posedge b_clk or negedge b_rst_n) begin
        if (~b_rst_n) begin
            b_wptr <= {ASIZE{1'b0}};
        end else if (b_winc) begin
            b_wptr <= b_wptr_next;
        end
    end

    // Count
    always @(posedge a_clk or negedge a_rst_n) begin
        if (~a_rst_n) begin
            a_count <= {ASIZE+1{1'b0}};
        end else begin
            a_count <= a_count_next;
        end
    end

    // Count
    always @(posedge b_clk or negedge b_rst_n) begin
        if (~b_rst_n) begin
            b_count <= {ASIZE+1{1'b0}};
        end else begin
            b_count <= b_count_next;
        end
    end

    // Write pointer next
    assign a_wptr_next = (a_dir) ? a_wptr : a_rptr;

    // Read pointer next
    assign a_rptr_next = (a_dir) ? a_rptr : a_wptr;

    // Write pointer next
    assign b_wptr_next = (b_dir) ? b_wptr : b_rptr;

    // Read pointer next
    assign b_rptr_next = (b_dir) ? b_rptr : b_wptr;

    // Count next
    assign a_count_next = (a_dir) ? a_count + {1'b0, a_winc} - {1'b0, a_rinc} : a_count;

    // Count next
    assign b_count_next = (b_dir) ? b_count + {1'b0, b_winc} - {1'b0, b_rinc} : b_count;

    // Full next
    assign a_full_next = (a_count == FSIZE);

    // Almost full next
    assign a_afull_next = (a_count == FSIZE_M1);

    // Empty next
    assign a_empty_next = (a_count == 0);

    // Almost empty next
    assign a_aempty_next = (a_count == 1);

    // Full next
    assign b_full_next = (b_count == FSIZE);

    // Almost full next
    assign b_afull_next = (b_count == FSIZE_M1);

    // Empty next
    assign b_empty_next = (b_count == 0);

    // Almost empty next
    assign b_aempty_next = (b_count == 1);

    // Read data next
    assign a_rdata_next = a_mem[a_rptr];

    // Read data next
    assign b_rdata_next = b_mem[b_rptr];

    // Memory
    always @(posedge a_clk or negedge a_rst_n) begin
        if (~a_rst_n) begin
            for (int i = 0; i < FSIZE; i = i + 1) begin
                a_mem[i] <= {DSIZE{1'b0}};
            end
        end else if (a_winc && ~a_dir) begin
            a_mem[a_wptr] <= a_wdata;
        end
    end

    // Memory
    always @(posedge b_clk or negedge b_rst_n) begin
        if (~b_rst_n) begin
            for (int i = 0; i < FSIZE; i = i + 1) begin
                b_mem[i] <= {DSIZE{1'b0}};
            end
        end else if (b_winc && ~b_dir) begin
            b_mem[b_wptr] <= b_wdata;
        end
    end

    // Outputs
    assign a_rdata = a_rdata_next;
    assign a_full = a_full_next;
    assign a_afull = a_afull_next;
    assign a_empty = a_empty_next;
    assign a_aempty = a_aempty_next;
    assign b_rdata = b_rdata_next;
    assign b_full = b_full_next;
    assign b_afull = b_afull_next;
    assign b_empty = b_empty_next;
    assign b_aempty = b_aempty_next;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    wire [7:0] temp;

    adder adder_inst (
        .a(a),
        .b(b),
        .sum(temp)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum <= 8'b0;
        end else begin
            sum <= temp;
        end
    end

endmodule

module adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    assign sum = a + b;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    wire [7:0] temp;

    adder adder_inst (
        .a(a),
        .b(b),
        .sum(temp)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum <= 8'b0;
        end else begin
            sum <= temp;
        end
    end

endmodule

module adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    assign sum = a + b;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    wire [7:0] temp;

    adder adder_inst (
        .a(a),
        .b(b),
        .sum(temp)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum <= 8'b0;
        end else begin
            sum <= temp;
        end
    end

endmodule

module adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    assign sum = a + b;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    wire [7:0] temp;

    adder adder_inst (
        .a(a),
        .b(b),
        .sum(temp)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum <= 8'b0;
        end else begin
            sum <= temp;
        end
    end

endmodule

module adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

    assign sum = a + b;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder_tb;

    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    adder dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        a = 8'b0;
        b = 8'b0;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
        b = 8'b00001111;
        #10 $finish;
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] a;
    reg [7:0] b;
    wire [7:0] sum;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'b0;
        b = 8'b0;
        #10 rst_n = 1;
        #10 a = 8'b10101010;
        b = 8'b11110000;
        #10 a = 8'b01010101;
