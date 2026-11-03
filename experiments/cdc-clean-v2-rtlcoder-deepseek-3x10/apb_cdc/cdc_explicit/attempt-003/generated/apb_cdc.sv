The APB clock-domain bridge can be implemented using two FIFOs, one for each direction of the bridge. The source FIFO stores the incoming APB transactions, and the destination FIFO stores the outgoing APB transactions. The FIFOs are implemented using a simple shift register with a write pointer and a read pointer.

The source FIFO is clocked by the src_pclk_i clock, and the destination FIFO is clocked by the dst_pclk_i clock. The FIFOs are reset by the src_preset_ni and dst_preset_ni reset signals, respectively.

The source FIFO is populated by the src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, and src_pprot_i signals. The destination FIFO is populated by the dst_pready_i signal.

The src_pready_o signal is asserted when the source FIFO is not empty and the destination FIFO is not full. The src_prdata_o signal is driven by the dst_prdata_i signal, and the src_pslverr_o signal is driven by the dst_pslverr_i signal.

The dst_psel_o, dst_penable_o, dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, and dst_pprot_o signals are driven by the destination FIFO. The dst_pready_i signal is asserted when the destination FIFO is not empty.

The complete Verilog code for the APB clock-domain bridge is as follows:

```
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Source FIFO
    reg [ADDR_WIDTH-1:0] src_paddr_fifo [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH-1:0] src_pwdata_fifo [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH/8-1:0] src_pstrb_fifo [0:2**LOG_DEPTH-1];
    reg [2:0] src_pprot_fifo [0:2**LOG_DEPTH-1];
    reg src_psel_fifo [0:2**LOG_DEPTH-1];
    reg src_penable_fifo [0:2**LOG_DEPTH-1];
    reg src_pwrite_fifo [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH-1:0] src_write_ptr = 0;
    reg [LOG_DEPTH-1:0] src_read_ptr = 0;
    reg [LOG_DEPTH-1:0] src_count = 0;

    // Destination FIFO
    reg [ADDR_WIDTH-1:0] dst_paddr_fifo [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH-1:0] dst_pwdata_fifo [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH/8-1:0] dst_pstrb_fifo [0:2**LOG_DEPTH-1];
    reg [2:0] dst_pprot_fifo [0:2**LOG_DEPTH-1];
    reg dst_psel_fifo [0:2**LOG_DEPTH-1];
    reg dst_penable_fifo [0:2**LOG_DEPTH-1];
    reg dst_pwrite_fifo [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH-1:0] dst_write_ptr = 0;
    reg [LOG_DEPTH-1:0] dst_read_ptr = 0;
    reg [LOG_DEPTH-1:0] dst_count = 0;

    // Source FIFO push
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 0) begin
            src_write_ptr <= 0;
            src_read_ptr <= 0;
            src_count <= 0;
        end else if (src_psel_i && src_penable_i && src_count < 2**LOG_DEPTH) begin
            src_paddr_fifo[src_write_ptr] <= src_paddr_i;
            src_pwdata_fifo[src_write_ptr] <= src_pwdata_i;
            src_pstrb_fifo[src_write_ptr] <= src_pstrb_i;
            src_pprot_fifo[src_write_ptr] <= src_pprot_i;
            src_psel_fifo[src_write_ptr] <= src_psel_i;
            src_penable_fifo[src_write_ptr] <= src_penable_i;
            src_pwrite_fifo[src_write_ptr] <= src_pwrite_i;
            src_write_ptr <= src_write_ptr + 1;
            src_count <= src_count + 1;
        end
    end

    // Source FIFO pop
    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 0) begin
            dst_write_ptr <= 0;
            dst_read_ptr <= 0;
            dst_count <= 0;
        end else if (dst_pready_i && dst_count < 2**LOG_DEPTH) begin
            dst_paddr_fifo[dst_write_ptr] <= src_paddr_fifo[src_read_ptr];
            dst_pwdata_fifo[dst_write_ptr] <= src_pwdata_fifo[src_read_ptr];
            dst_pstrb_fifo[dst_write_ptr] <= src_pstrb_fifo[src_read_ptr];
            dst_pprot_fifo[dst_write_ptr] <= src_pprot_fifo[src_read_ptr];
            dst_psel_fifo[dst_write_ptr] <= src_psel_fifo[src_read_ptr];
            dst_penable_fifo[dst_write_ptr] <= src_penable_fifo[src_read_ptr];
            dst_pwrite_fifo[dst_write_ptr] <= src_pwrite_fifo[src_read_ptr];
            dst_write_ptr <= dst_write_ptr + 1;
            dst_count <= dst_count + 1;
            src_read_ptr <= src_read_ptr + 1;
            src_count <= src_count - 1;
        end
    end

    // Source FIFO output
    assign src_pready_o = (src_count > 0) && (dst_count < 2**LOG_DEPTH);
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination FIFO output
    assign dst_psel_o = dst_psel_fifo[dst_read_ptr];
    assign dst_penable_o = dst_penable_fifo[dst_read_ptr];
    assign dst_pwrite_o = dst_pwrite_fifo[dst_read_ptr];
    assign dst_paddr_o = dst_paddr_fifo[dst_read_ptr];
    assign dst_pwdata_o = dst_pwdata_fifo[dst_read_ptr];
    assign dst_pstrb_o = dst_pstrb_fifo[dst_read_ptr];
    assign dst_pprot_o = dst_pprot_fifo[dst_read_ptr];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Verilog Module my_module
//
// Created on: Wed Jun 23 15:00:47 2022
//
// Copyright (c) 2022 by VLSI Technology Systems, Inc.,
// All rights reserved.
//
// This source file is confidential and contains trade secrets that are
// proprietary to VLSI Technology Systems, Inc.  Use, disclosure, or
// reproduction is prohibited without prior written consent from VLSI
// Technology Systems, Inc.
//
//
module my_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    my_module my_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8'b0;
        end else begin
            out <= in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 8