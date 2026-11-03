The AXI4 clock-domain bridge can be implemented using a pair of FIFOs to buffer the incoming and outgoing data. The incoming data is buffered in the S_AXI_FIFO and the outgoing data is buffered in the M_AXI_FIFO. The FIFOs are implemented using a simple shift register with a depth of 2^LGFIFO.

The following Verilog code implements the AXI4 clock-domain bridge:

```
module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	// S_AXI_FIFO
	reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_FIFO [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] S_AXI_FIFO_head = 0;
	reg [LGFIFO-1:0] S_AXI_FIFO_tail = 0;
	reg [LGFIFO-1:0] S_AXI_FIFO_count = 0;
	reg S_AXI_FIFO_full = 0;
	reg S_AXI_FIFO_empty = 1;

	// M_AXI_FIFO
	reg [C_S_AXI_DATA_WIDTH-1:0] M_AXI_FIFO [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] M_AXI_FIFO_head = 0;
	reg [LGFIFO-1:0] M_AXI_FIFO_tail = 0;
	reg [LGFIFO-1:0] M_AXI_FIFO_count = 0;
	reg M_AXI_FIFO_full = 0;
	reg M_AXI_FIFO_empty = 1;

	// S_AXI_FIFO_push
	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARESETN == 0) begin
			S_AXI_FIFO_head <= 0;
			S_AXI_FIFO_tail <= 0;
			S_AXI_FIFO_count <= 0;
			S_AXI_FIFO_full <= 0;
			S_AXI_FIFO_empty <= 1;
		end else begin
			if (S_AXI_WVALID && !S_AXI_FIFO_full) begin
				S_AXI_FIFO[S_AXI_FIFO_head] <= S_AXI_WDATA;
				S_AXI_FIFO_head <= S_AXI_FIFO_head + 1;
				S_AXI_FIFO_count <= S_AXI_FIFO_count + 1;
				if (S_AXI_FIFO_count == 2**LGFIFO-1) begin
					S_AXI_FIFO_full <= 1;
				end
				S_AXI_FIFO_empty <= 0;
			end
			if (S_AXI_BREADY && !S_AXI_FIFO_empty) begin
				S_AXI_FIFO_tail <= S_AXI_FIFO_tail + 1;
				S_AXI_FIFO_count <= S_AXI_FIFO_count - 1;
				if (S_AXI_FIFO_count == 1) begin
					S_AXI_FIFO_empty <= 1;
				end
				S_AXI_FIFO_full <= 0;
			end
		end
	end

	// M_AXI_FIFO_push
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			M_AXI_FIFO_head <= 0;
			M_AXI_FIFO_tail <= 0;
			M_AXI_FIFO_count <= 0;
			M_AXI_FIFO_full <= 0;
			M_AXI_FIFO_empty <= 1;
		end else begin
			if (M_AXI_RVALID && !M_AXI_FIFO_full) begin
				M_AXI_FIFO[M_AXI_FIFO_head] <= M_AXI_RDATA;
				M_AXI_FIFO_head <= M_AXI_FIFO_head + 1;
				M_AXI_FIFO_count <= M_AXI_FIFO_count + 1;
				if (M_AXI_FIFO_count == 2**LGFIFO-1) begin
					M_AXI_FIFO_full <= 1;
				end
				M_AXI_FIFO_empty <= 0;
			end
			if (M_AXI_BREADY && !M_AXI_FIFO_empty) begin
				M_AXI_FIFO_tail <= M_AXI_FIFO_tail + 1;
				M_AXI_FIFO_count <= M_AXI_FIFO_count - 1;
				if (M_AXI_FIFO_count == 1) begin
					M_AXI_FIFO_empty <= 1;
				end
				M_AXI_FIFO_full <= 0;
			end
		end
	end

	// S_AXI_FIFO_pop
	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARESETN == 0) begin
			S_AXI_WREADY <= 0;
			S_AXI_BVALID <= 0;
			S_AXI_BID <= 0;
			S_AXI_BRESP <= 0;
		end else begin
			if (S_AXI_WVALID && !S_AXI_FIFO_empty) begin
				S_AXI_WREADY <= 1;
				S_AXI_BVALID <= 0;
				S_AXI_BID <= 0;
				S_AXI_BRESP <= 0;
			end else begin
				S_AXI_WREADY <= 0;
				if (S_AXI_BREADY && !S_AXI_FIFO_empty) begin
					S_AXI_BVALID <= 1;
					S_AXI_BID <= S_AXI_FIFO[S_AXI_FIFO_tail][C_S_AXI_ID_WIDTH-1:0];
					S_AXI_BRESP <= 0;
				end else begin
					S_AXI_BVALID <= 0;
					S_AXI_BID <= 0;
					S_AXI_BRESP <= 0;
				end
			end
		end
	end

	// M_AXI_FIFO_pop
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			M_AXI_RVALID <= 0;
			M_AXI_RID <= 0;
			M_AXI_RDATA <= 0;
			M_AXI_RRESP <= 0;
			M_AXI_RLAST <= 0;
		end else begin
			if (M_AXI_ARVALID && !M_AXI_FIFO_empty) begin
				M_AXI_RVALID <= 1;
				M_AXI_RID <= M_AXI_FIFO[M_AXI_FIFO_tail][C_S_AXI_ID_WIDTH-1:0];
				M_AXI_RDATA <= M_AXI_FIFO[M_AXI_FIFO_tail][C_S_AXI_DATA_WIDTH-1:0];
				M_AXI_RRESP <= 0;
				M_AXI_RLAST <= 0;
			end else begin
				M_AXI_RVALID <= 0;
				M_AXI_RID <= 0;
				M_AXI_RDATA <= 0;
				M_AXI_RRESP <= 0;
				M_AXI_RLAST <= 0;
			end
		end
	end

	// S_AXI_FIFO_push_M_AXI_FIFO_pop
	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARESETN == 0) begin
			S_AXI_AWREADY <= 0;
			S_AXI_ARREADY <= 0;
			M_AXI_AWVALID <= 0;
			M_AXI_WVALID <= 0;
			M_AXI_BREADY <= 0;
			M_AXI_ARVALID <= 0;
			M_AXI_RREADY <= 0;
		end else begin
			if (S_AXI_AWVALID && !S_AXI_FIFO_full) begin
				S_AXI_AWREADY <= 1;
				M_AXI_AWVALID <= 1;
				M_AXI_AWID <= S_AXI_AWID;
				M_AXI_AWADDR <= S_AXI_AWADDR;
				M_AXI_AWLEN <= S_AXI_AWLEN;
				M_AXI_AWSIZE <= S_AXI_AWSIZE;
				M_AXI_AWBURST <= S_AXI_AWBURST;
				M_AXI_AWLOCK <= S_AXI_AWLOCK;
				M_AXI_AWCACHE <= S_AXI_AWCACHE;
				M_AXI_AWPROT <= S_AXI_AWPROT;
				M_AXI_AWQOS <= S_AXI_AWQOS;
				M_AXI_WVALID <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end else begin
				S_AXI_AWREADY <= 0;
				M_AXI_AWVALID <= 0;
				M_AXI_AWID <= 0;
				M_AXI_AWADDR <= 0;
				M_AXI_AWLEN <= 0;
				M_AXI_AWSIZE <= 0;
				M_AXI_AWBURST <= 0;
				M_AXI_AWLOCK <= 0;
				M_AXI_AWCACHE <= 0;
				M_AXI_AWPROT <= 0;
				M_AXI_AWQOS <= 0;
				M_AXI_WVALID <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end
			if (S_AXI_WVALID && !S_AXI_FIFO_full) begin
				S_AXI_WREADY <= 1;
				M_AXI_WVALID <= 1;
				M_AXI_WDATA <= S_AXI_WDATA;
				M_AXI_WSTRB <= S_AXI_WSTRB;
				M_AXI_WLAST <= S_AXI_WLAST;
				M_AXI_BREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end else begin
				S_AXI_WREADY <= 0;
				M_AXI_WVALID <= 0;
				M_AXI_WDATA <= 0;
				M_AXI_WSTRB <= 0;
				M_AXI_WLAST <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end
			if (S_AXI_BREADY && !S_AXI_FIFO_empty) begin
				S_AXI_BVALID <= 1;
				S_AXI_BID <= S_AXI_FIFO[S_AXI_FIFO_tail][C_S_AXI_ID_WIDTH-1:0];
				S_AXI_BRESP <= 0;
				M_AXI_BREADY <= 1;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end else begin
				S_AXI_BVALID <= 0;
				S_AXI_BID <= 0;
				S_AXI_BRESP <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_RREADY <= 0;
			end
			if (S_AXI_ARVALID && !S_AXI_FIFO_full) begin
				S_AXI_ARREADY <= 1;
				M_AXI_ARVALID <= 1;
				M_AXI_ARID <= S_AXI_ARID;
				M_AXI_ARADDR <= S_AXI_ARADDR;
				M_AXI_ARLEN <= S_AXI_ARLEN;
				M_AXI_ARSIZE <= S_AXI_ARSIZE;
				M_AXI_ARBURST <= S_AXI_ARBURST;
				M_AXI_ARLOCK <= S_AXI_ARLOCK;
				M_AXI_ARCACHE <= S_AXI_ARCACHE;
				M_AXI_ARPROT <= S_AXI_ARPROT;
				M_AXI_ARQOS <= S_AXI_ARQOS;
				M_AXI_WVALID <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_RREADY <= 0;
			end else begin
				S_AXI_ARREADY <= 0;
				M_AXI_ARVALID <= 0;
				M_AXI_ARID <= 0;
				M_AXI_ARADDR <= 0;
				M_AXI_ARLEN <= 0;
				M_AXI_ARSIZE <= 0;
				M_AXI_ARBURST <= 0;
				M_AXI_ARLOCK <= 0;
				M_AXI_ARCACHE <= 0;
				M_AXI_ARPROT <= 0;
				M_AXI_ARQOS <= 0;
				M_AXI_WVALID <= 0;
				M_AXI_BREADY <= 0;
				M_AXI_RREADY <= 0;
			end
			if (M_AXI_RVALID && !M_AXI_FIFO_empty) begin
				M_AXI_RREADY <= 1;
				S_AXI_RVALID <= 1;
				S_AXI_RID <= M_AXI_FIFO[M_AXI_FIFO_tail][C_S_AXI_ID_WIDTH-1:0];
				S_AXI_RDATA <= M_AXI_FIFO[M_AXI_FIFO_tail][C_S_AXI_DATA_WIDTH-1:0];
				S_AXI_RRESP <= 0;
				S_AXI_RLAST <= 0;
				S_AXI_AWREADY <= 0;
				S_AXI_ARREADY <= 0;
				S_AXI_WREADY <= 0;
				S_AXI_BVALID <= 0;
				S_AXI_BID <= 0;
				S_AXI_BRESP <= 0;
			end else begin
				M_AXI_RREADY <= 0;
				S_AXI_RVALID <= 0;
				S_AXI_RID <= 0;
				S_AXI_RDATA <= 0;
				S_AXI_RRESP <= 0;
				S_AXI_RLAST <= 0;
				S_AXI_AWREADY <= 0;
				S_AXI_ARREADY <= 0;
				S_AXI_WREADY <= 0;
				S_AXI_BVALID <= 0;
				S_AXI_BID <= 0;
				S_AXI_BRESP <= 0;
			end
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
            3'b00