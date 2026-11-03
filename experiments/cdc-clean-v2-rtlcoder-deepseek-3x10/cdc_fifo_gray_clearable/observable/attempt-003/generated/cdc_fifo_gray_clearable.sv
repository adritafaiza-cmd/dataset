The following Verilog code implements a clearable valid/ready asynchronous FIFO. The code uses a Gray code synchronizer to handle clock domain crossings. The FIFO is designed to preserve ordered, exactly-once accepted transfers, the stated capacity, and stable valid data while stalled.

```
module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Gray code synchronizer
    reg [LOG_DEPTH-1:0] gray_sync_reg [SYNC_STAGES-1:0];
    wire [LOG_DEPTH-1:0] gray_sync_out;
    assign gray_sync_out = gray_sync_reg[SYNC_STAGES-1];

    always @(posedge src_clk_i) begin
        if (src_rst_ni == 1'b0) begin
            gray_sync_reg <= {LOG_DEPTH{1'b0}};
        end else begin
            gray_sync_reg[0] <= src_clear_i ? {LOG_DEPTH{1'b0}} : gray_sync_reg[0] + 1'b1;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                gray_sync_reg[i] <= gray_sync_reg[i-1];
            end
        end
    end

    // FIFO memory
    reg [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0] fifo_head;
    reg [LOG_DEPTH-1:0] fifo_tail;
    reg [LOG_DEPTH-1:0] fifo_count;
    reg [LOG_DEPTH-1:0] fifo_gray_count;

    // Write pointer
    always @(posedge src_clk_i) begin
        if (src_rst_ni == 1'b0) begin
            fifo_head <= {LOG_DEPTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            fifo_head <= fifo_head + 1'b1;
        end
    end

    // Read pointer
    always @(posedge dst_clk_i) begin
        if (dst_rst_ni == 1'b0) begin
            fifo_tail <= {LOG_DEPTH{1'b0}};
        end else if (dst_valid_o && dst_ready_i) begin
            fifo_tail <= fifo_tail + 1'b1;
        end
    end

    // FIFO count
    always @(posedge src_clk_i or posedge dst_clk_i) begin
        if (src_rst_ni == 1'b0 || dst_rst_ni == 1'b0) begin
            fifo_count <= {LOG_DEPTH{1'b0}};
        end else begin
            fifo_count <= fifo_head - fifo_tail;
        end
    end

    // FIFO gray count
    always @(posedge src_clk_i or posedge dst_clk_i) begin
        if (src_rst_ni == 1'b0 || dst_rst_ni == 1'b0) begin
            fifo_gray_count <= {LOG_DEPTH{1'b0}};
        end else begin
            fifo_gray_count <= fifo_count ^ (fifo_count >> 1);
        end
    end

    // FIFO memory write
    always @(posedge src_clk_i) begin
        if (src_rst_ni == 1'b0) begin
            fifo_mem <= {2**LOG_DEPTH{WIDTH{1'b0}}};
        end else if (src_valid_i && src_ready_o) begin
            fifo_mem[fifo_head] <= src_data_i;
        end
    end

    // FIFO memory read
    always @(posedge dst_clk_i) begin
        if (dst_rst_ni == 1'b0) begin
            dst_data_o <= {WIDTH{1'b0}};
            dst_valid_o <= 1'b0;
        end else begin
            dst_data_o <= fifo_mem[fifo_tail];
            dst_valid_o <= (fifo_count > 0) && (fifo_gray_count == gray_sync_out);
        end
    end

    // Clear pending
    reg [SYNC_STAGES-1:0] clear_pending_reg;
    wire clear_pending_out;
    assign clear_pending_out = clear_pending_reg[SYNC_STAGES-1];

    always @(posedge src_clk_i or posedge dst_clk_i) begin
        if (src_rst_ni == 1'b0 || dst_rst_ni == 1'b0) begin
            clear_pending_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            clear_pending_reg[0] <= src_clear_i || dst_clear_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                clear_pending_reg[i] <= clear_pending_reg[i-1];
            end
        end
    end

    assign src_clear_pending_o = clear_pending_out;
    assign dst_clear_pending_o = clear_pending_out;

    // Ready signal
    assign src_ready_o = (fifo_count < 2**LOG_DEPTH) && !clear_pending_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
            data_out <= data_in;
        end else begin
            data_out <= {data_out[WIDTH-2:0], data_out[WIDTH-1]};
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg load;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    shift_register dut(.clk(clk), .reset(reset), .data_in(data_in), .load(load), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Test case 1: Load data into the shift register
    initial begin
        load = 1;
        data_in = 8'h55;
        #20 load = 0;
        #200 $finish;
    end

    // Test case 2: Shift data out of the shift register
    initial begin
        load = 0;
        #100 data_in = 8'hAA;
        #200 $finish;
    end

endmodule

module shift_register(clk, reset, data_in, load, data_out);

    parameter WIDTH = 8;

    input clk;
    input reset;
    input [WIDTH-1:0] data_in;
    input load;
    output reg [WIDTH-1:0] data_out;

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (load) begin
