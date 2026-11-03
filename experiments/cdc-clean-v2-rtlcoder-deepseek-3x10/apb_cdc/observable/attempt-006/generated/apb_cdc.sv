Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge. This code uses two FIFOs to store the APB requests and responses, and two synchronizers to handle the clock domain crossings.

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

    // FIFO for APB requests
    localparam REQ_FIFO_DEPTH = 2**LOG_DEPTH;
    reg [ADDR_WIDTH-1:0] req_fifo_data [0:REQ_FIFO_DEPTH-1];
    reg [LOG_DEPTH-1:0] req_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] req_fifo_rd_ptr;
    wire req_fifo_full = (req_fifo_wr_ptr == req_fifo_rd_ptr) && (req_fifo_wr_ptr != REQ_FIFO_DEPTH-1);
    wire req_fifo_empty = (req_fifo_wr_ptr == req_fifo_rd_ptr) && (req_fifo_wr_ptr == 0);

    // FIFO for APB responses
    localparam RESP_FIFO_DEPTH = 2**LOG_DEPTH;
    reg [DATA_WIDTH-1:0] resp_fifo_data [0:RESP_FIFO_DEPTH-1];
    reg [LOG_DEPTH-1:0] resp_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] resp_fifo_rd_ptr;
    wire resp_fifo_full = (resp_fifo_wr_ptr == resp_fifo_rd_ptr) && (resp_fifo_wr_ptr != RESP_FIFO_DEPTH-1);
    wire resp_fifo_empty = (resp_fifo_wr_ptr == resp_fifo_rd_ptr) && (resp_fifo_wr_ptr == 0);

    // Synchronizers for APB signals
    reg src_psel_sync;
    reg src_penable_sync;
    reg src_pwrite_sync;
    reg [ADDR_WIDTH-1:0] src_paddr_sync;
    reg [DATA_WIDTH-1:0] src_pwdata_sync;
    reg [DATA_WIDTH/8-1:0] src_pstrb_sync;
    reg [2:0] src_pprot_sync;
    reg dst_psel_sync;
    reg dst_penable_sync;
    reg dst_pwrite_sync;
    reg [ADDR_WIDTH-1:0] dst_paddr_sync;
    reg [DATA_WIDTH-1:0] dst_pwdata_sync;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_sync;
    reg [2:0] dst_pprot_sync;

    always @(posedge src_pclk_i) begin
        if (!src_preset_ni) begin
            src_psel_sync <= 0;
            src_penable_sync <= 0;
            src_pwrite_sync <= 0;
            src_paddr_sync <= 0;
            src_pwdata_sync <= 0;
            src_pstrb_sync <= 0;
            src_pprot_sync <= 0;
        end else begin
            src_psel_sync <= src_psel_i;
            src_penable_sync <= src_penable_i;
            src_pwrite_sync <= src_pwrite_i;
            src_paddr_sync <= src_paddr_i;
            src_pwdata_sync <= src_pwdata_i;
            src_pstrb_sync <= src_pstrb_i;
            src_pprot_sync <= src_pprot_i;
        end
    end

    always @(posedge dst_pclk_i) begin
        if (!dst_preset_ni) begin
            dst_psel_sync <= 0;
            dst_penable_sync <= 0;
            dst_pwrite_sync <= 0;
            dst_paddr_sync <= 0;
            dst_pwdata_sync <= 0;
            dst_pstrb_sync <= 0;
            dst_pprot_sync <= 0;
        end else begin
            dst_psel_sync <= dst_psel_o;
            dst_penable_sync <= dst_penable_o;
            dst_pwrite_sync <= dst_pwrite_o;
            dst_paddr_sync <= dst_paddr_o;
            dst_pwdata_sync <= dst_pwdata_o;
            dst_pstrb_sync <= dst_pstrb_o;
            dst_pprot_sync <= dst_pprot_o;
        end
    end

    // APB request handling
    always @(posedge src_pclk_i) begin
        if (!src_preset_ni) begin
            req_fifo_wr_ptr <= 0;
            req_fifo_rd_ptr <= 0;
        end else begin
            if (src_psel_sync && src_penable_sync && !req_fifo_full) begin
                req_fifo_data[req_fifo_wr_ptr] <= {src_pwrite_sync, src_paddr_sync, src_pwdata_sync, src_pstrb_sync, src_pprot_sync};
                req_fifo_wr_ptr <= req_fifo_wr_ptr + 1;
            end
            if (dst_pready_i && !req_fifo_empty) begin
                dst_psel_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3];
                dst_penable_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2];
                dst_pwrite_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1];
                dst_paddr_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8-1:ADDR_WIDTH+DATA_WIDTH];
                dst_pwdata_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH-1:ADDR_WIDTH];
                dst_pstrb_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH-1:0];
                dst_pprot_sync <= req_fifo_data[req_fifo_rd_ptr][ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8-1:ADDR_WIDTH+DATA_WIDTH-1];
                req_fifo_rd_ptr <= req_fifo_rd_ptr + 1;
            end
        end
    end

    // APB response handling
    always @(posedge dst_pclk_i) begin
        if (!dst_preset_ni) begin
            resp_fifo_wr_ptr <= 0;
            resp_fifo_rd_ptr <= 0;
        end else begin
            if (dst_psel_sync && dst_penable_sync && !resp_fifo_full) begin
                resp_fifo_data[resp_fifo_wr_ptr] <= dst_prdata_i;
                resp_fifo_wr_ptr <= resp_fifo_wr_ptr + 1;
            end
            if (src_pready_o && !resp_fifo_empty) begin
                src_prdata_o <= resp_fifo_data[resp_fifo_rd_ptr];
                resp_fifo_rd_ptr <= resp_fifo_rd_ptr + 1;
            end
        end
    end

    // APB signals
    assign src_pready_o = !req_fifo_full;
    assign src_pslverr_o = dst_pslverr_i;
    assign dst_psel_o = src_psel_sync;
    assign dst_penable_o = src_penable_sync;
    assign dst_pwrite_o = src_pwrite_sync;
    assign dst_paddr_o = src_paddr_sync;
    assign dst_pwdata_o = src_pwdata_sync;
    assign dst_pstrb_o = src_pstrb_sync;
    assign dst_pprot_o = src_pprot_sync;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2