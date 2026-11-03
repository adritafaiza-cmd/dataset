Here is the complete Verilog code for the asynchronous FIFO module:

```
module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	localparam	FIFO_DEPTH = 1 << LGFIFO;

	reg [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO-1:0] wr_ptr;
	reg [LGFIFO-1:0] rd_ptr;
	reg [LGFIFO-1:0] wr_ptr_next;
	reg [LGFIFO-1:0] rd_ptr_next;

	wire wr_ptr_full = (wr_ptr_next == rd_ptr);
	wire rd_ptr_empty = (rd_ptr_next == wr_ptr);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (~i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_next <= 0;
			o_wr_full <= 0;
		end else begin
			wr_ptr <= wr_ptr_next;
			o_wr_full <= wr_ptr_full;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (~i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_next <= 0;
			o_rd_empty <= 1;
		end else begin
			rd_ptr <= rd_ptr_next;
			o_rd_empty <= rd_ptr_empty;
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (~i_wr_reset_n) begin
			fifo <= '{default: '0};
		end else if (i_wr && ~o_wr_full) begin
			fifo[wr_ptr] <= i_wr_data;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (~i_rd_reset_n) begin
			o_rd_data <= '0;
		end else if (i_rd && ~o_rd_empty) begin
			o_rd_data <= fifo[rd_ptr];
		end
	end

	always @(*) begin
		if (WRITE_ON_POSEDGE) begin
			wr_ptr_next = wr_ptr + 1'b1;
			rd_ptr_next = rd_ptr;
		end else begin
			wr_ptr_next = wr_ptr;
			rd_ptr_next = rd_ptr + 1'b1;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end