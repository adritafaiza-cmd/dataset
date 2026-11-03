The APB clock-domain bridge can be implemented using two synchronizers for each APB signal. The first synchronizer is used to transfer the APB signals from the source clock domain to the destination clock domain. The second synchronizer is used to transfer the APB signals from the destination clock domain back to the source clock domain.

Here is the complete Verilog-2001 code for the APB clock-domain bridge:

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

    // Synchronizers for APB signals
    reg [1:0] src_psel_sync;
    reg [1:0] src_penable_sync;
    reg [1:0] src_pwrite_sync;
    reg [1:0] src_paddr_sync;
    reg [1:0] src_pwdata_sync;
    reg [1:0] src_pstrb_sync;
    reg [1:0] src_pprot_sync;
    reg [1:0] src_pready_sync;
    reg [1:0] src_prdata_sync;
    reg [1:0] src_pslverr_sync;
    reg [1:0] dst_psel_sync;
    reg [1:0] dst_penable_sync;
    reg [1:0] dst_pwrite_sync;
    reg [1:0] dst_paddr_sync;
    reg [1:0] dst_pwdata_sync;
    reg [1:0] dst_pstrb_sync;
    reg [1:0] dst_pprot_sync;
    reg [1:0] dst_pready_sync;
    reg [1:0] dst_prdata_sync;
    reg [1:0] dst_pslverr_sync;

    // Synchronize APB signals
    always @(posedge src_pclk_i) begin
        src_psel_sync <= {src_psel_sync[0], src_psel_i};
        src_penable_sync <= {src_penable_sync[0], src_penable_i};
        src_pwrite_sync <= {src_pwrite_sync[0], src_pwrite_i};
        src_paddr_sync <= {src_paddr_sync[0], src_paddr_i};
        src_pwdata_sync <= {src_pwdata_sync[0], src_pwdata_i};
        src_pstrb_sync <= {src_pstrb_sync[0], src_pstrb_i};
        src_pprot_sync <= {src_pprot_sync[0], src_pprot_i};
        src_pready_sync <= {src_pready_sync[0], src_pready_o};
        src_prdata_sync <= {src_prdata_sync[0], src_prdata_o};
        src_pslverr_sync <= {src_pslverr_sync[0], src_pslverr_o};
    end

    always @(posedge dst_pclk_i) begin
        dst_psel_sync <= {dst_psel_sync[0], dst_psel_o};
        dst_penable_sync <= {dst_penable_sync[0], dst_penable_o};
        dst_pwrite_sync <= {dst_pwrite_sync[0], dst_pwrite_o};
        dst_paddr_sync <= {dst_paddr_sync[0], dst_paddr_o};
        dst_pwdata_sync <= {dst_pwdata_sync[0], dst_pwdata_o};
        dst_pstrb_sync <= {dst_pstrb_sync[0], dst_pstrb_o};
        dst_pprot_sync <= {dst_pprot_sync[0], dst_pprot_o};
        dst_pready_sync <= {dst_pready_sync[0], dst_pready_i};
        dst_prdata_sync <= {dst_prdata_sync[0], dst_prdata_i};
        dst_pslverr_sync <= {dst_pslverr_sync[0], dst_pslverr_i};
    end

    // Assign synchronized APB signals to output ports
    assign src_psel_o = src_psel_sync[1];
    assign src_penable_o = src_penable_sync[1];
    assign src_pwrite_o = src_pwrite_sync[1];
    assign src_paddr_o = src_paddr_sync[1];
    assign src_pwdata_o = src_pwdata_sync[1];
    assign src_pstrb_o = src_pstrb_sync[1];
    assign src_pprot_o = src_pprot_sync[1];
    assign src_pready_o = src_pready_sync[1];
    assign src_prdata_o = src_prdata_sync[1];
    assign src_pslverr_o = src_pslverr_sync[1];
    assign dst_psel_o = dst_psel_sync[1];
    assign dst_penable_o = dst_penable_sync[1];
    assign dst_pwrite_o = dst_pwrite_sync[1];
    assign dst_paddr_o = dst_paddr_sync[1];
    assign dst_pwdata_o = dst_pwdata_sync[1];
    assign dst_pstrb_o = dst_pstrb_sync[1];
    assign dst_pprot_o = dst_pprot_sync[1];
    assign dst_pready_o = dst_pready_sync[1];
    assign dst_prdata_o = dst_prdata_sync[1];
    assign dst_pslverr_o = dst_pslverr_sync[1];

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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
                shift_reg <= {shift_reg[4:0], shift_reg[6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[5]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[3]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[2]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[1:0]};
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
        state <= 3