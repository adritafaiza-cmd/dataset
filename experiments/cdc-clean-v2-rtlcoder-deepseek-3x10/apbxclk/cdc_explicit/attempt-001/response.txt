Here is the complete Verilog code for the APB clock-domain bridge module:

```
module apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	reg [1:0] state;
	reg [AW-1:0] addr;
	reg [DW-1:0] wdata;
	reg [DW/8-1:0] wstrb;
	reg [2:0] prot;
	reg write;
	reg sel;
	reg enable;
	reg [DW-1:0] rdata;
	reg slverr;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			state <= 2'b00;
			sel <= 1'b0;
			enable <= 1'b0;
			M_PRESETn <= 1'b0;
		end else begin
			case (state)
				2'b00: begin // Idle
					if (S_APB_PSEL && S_APB_PENABLE) begin
						state <= 2'b01;
						addr <= S_APB_PADDR;
						wdata <= S_APB_PWDATA;
						wstrb <= S_APB_PWSTRB;
						prot <= S_APB_PPROT;
						write <= S_APB_PWRITE;
						sel <= 1'b1;
						enable <= 1'b1;
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b1;
						M_APB_PADDR <= S_APB_PADDR;
						M_APB_PWRITE <= S_APB_PWRITE;
						M_APB_PWDATA <= S_APB_PWDATA;
						M_APB_PWSTRB <= S_APB_PWSTRB;
						M_APB_PPROT <= S_APB_PPROT;
					end
				end
				2'b01: begin // Setup phase
					if (M_APB_PREADY) begin
						state <= 2'b10;
						M_APB_PENABLE <= 1'b0;
					end
				end
				2'b10: begin // Access phase
					if (M_APB_PREADY) begin
						state <= 2'b00;
						sel <= 1'b0;
						enable <= 1'b0;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						S_APB_PREADY <= 1'b1;
						rdata <= M_APB_PRDATA;
						slverr <= M_APB_PSLVERR;
					end
				end
			endcase
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
		end
	end

	assign S_APB_PRDATA = rdata;
	assign S_APB_PSLVERR = slverr;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [3:0] in,
    output wire [3:0] out
);

    reg [3:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= 4'b0000;
        end else begin
            case (state)
                4'b0000: begin
                    state <= 4'b0001;
                end
                4'b0001: begin
                    state <= 4'b0010;
                end
                4'b0010: begin
                    state <= 4'b0011;
                end
                4'b0011: begin
                    state <= 4'b0100;
                end
                4'b0100: begin
                    state <= 4'b0101;
                end
                4'b0101: begin
                    state <= 4'b0110;
                end
                4'b0110: begin
                    state <= 4'b0111;
                end
                4'b0111: begin
                    state <= 4'b1000;
                end
                4'b1000: begin
                    state <= 4'b1001;
                end
                4'b1001: begin
                    state <= 4'b1010;
                end
                4'b1010: begin
                    state <= 4'b1011;
                end
                4'b1011: begin
                    state <= 4'b1100;
                end
                4'b1100: begin
                    state <= 4'b1101;
                end
                4'b1101: begin
                    state <= 4'b1110;
                end
                4'b1110: begin
                    state <= 4'b1111;
                end
                4'b1111: begin
                    state <= 4'b0000;
                end
            endcase
        end
    end

    assign out = state;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [3:0] in,
    output wire [3:0] out
);

    reg [3:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= 4'b0000;
        end else begin
            case (state)
                4'b0000: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0000;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0001;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0010;
                    end else if (in == 4'b0011) begin
                        state <= 4'b0011;
                    end else if (in == 4'b0100) begin
                        state <= 4'b0100;
                    end else if (in == 4'b0101) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0110) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0111) begin
                        state <= 4'b0111;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1000;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1001;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1010;
                    end else if (in == 4'b1011) begin
                        state <= 4'b1011;
                    end else if (in == 4'b1100) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1101) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1110) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1111) begin
                        state <= 4'b1111;
                    end
                end
                4'b0001: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0001;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0010;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0011;
                    end else if (in == 4'b0011) begin
                        state <= 4'b0100;
                    end else if (in == 4'b0100) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0101) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0110) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1000;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1001;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1010;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1011;
                    end else if (in == 4'b1011) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1100) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1101) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1110) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0000;
                    end
                end
                4'b0010: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0010;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0011;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0100;
                    end else if (in == 4'b0011) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0100) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0101) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1001;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1010;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1011;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1011) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1100) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1101) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0001;
                    end
                end
                4'b0011: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0011;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0100;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0011) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0100) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1010;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1011;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1011) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1100) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0010;
                    end
                end
                4'b0100: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0100;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0011) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1011;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1011) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0011;
                    end
                end
                4'b0101: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0101;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0010) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1100;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1010) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0100;
                    end
                end
                4'b0110: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0110;
                    end else if (in == 4'b0001) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1101;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1001) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0101;
                    end
                end
                4'b0111: begin
                    if (in == 4'b0000) begin
                        state <= 4'b0111;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1110;
                    end else if (in == 4'b1000) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0110;
                    end
                end
                4'b1000: begin
                    if (in == 4'b0000) begin
                        state <= 4'b1000;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1110;
                    end else if (in == 4'b0111) begin
                        state <= 4'b1111;
                    end else if (in == 4'b1000) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0110;
                    end else if (in == 4'b1111) begin
                        state <= 4'b0111;
                    end
                end
                4'b1001: begin
                    if (in == 4'b0000) begin
                        state <= 4'b1001;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1110;
                    end else if (in == 4'b0110) begin
                        state <= 4'b1111;
                    end else if (in == 4'b0111) begin
                        state <= 4'b0000;
                    end else if (in == 4'b1000) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0110;
                    end else if (in == 4'b1110) begin
                        state <= 4'b0111;
                    end else if (in == 4'b1111) begin
                        state <= 4'b1000;
                    end
                end
                4'b1010: begin
                    if (in == 4'b0000) begin
                        state <= 4'b1010;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1110;
                    end else if (in == 4'b0101) begin
                        state <= 4'b1111;
                    end else if (in == 4'b0110) begin
                        state <= 4'b0000;
                    end else if (in == 4'b0111) begin
                        state <= 4'b0001;
                    end else if (in == 4'b1000) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0110;
                    end else if (in == 4'b1101) begin
                        state <= 4'b0111;
                    end else if (in == 4'b1110) begin
                        state <= 4'b1000;
                    end else if (in == 4'b1111) begin
                        state <= 4'b1001;
                    end
                end
                4'b1011: begin
                    if (in == 4'b0000) begin
                        state <= 4'b1011;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1110;
                    end else if (in == 4'b0100) begin
                        state <= 4'b1111;
                    end else if (in == 4'b0101) begin
                        state <= 4'b0000;
                    end else if (in == 4'b0110) begin
                        state <= 4'b0001;
                    end else if (in == 4'b0111) begin
                        state <= 4'b0010;
                    end else if (in == 4'b1000) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0110;
                    end else if (in == 4'b1100) begin
                        state <= 4'b0111;
                    end else if (in == 4'b1101) begin
                        state <= 4'b1000;
                    end else if (in == 4'b1110) begin
                        state <= 4'b1001;
                    end else if (in == 4'b1111) begin
                        state <= 4'b1010;
                    end
                end
                4'b1100: begin
                    if (in == 4'b0000) begin
                        state <= 4'b1100;
                    end else if (in == 4'b0001) begin
                        state <= 4'b1101;
                    end else if (in == 4'b0010) begin
                        state <= 4'b1110;
                    end else if (in == 4'b0011) begin
                        state <= 4'b1111;
                    end else if (in == 4'b0100) begin
                        state <= 4'b0000;
                    end else if (in == 4'b0101) begin
                        state <= 4'b0001;
                    end else if (in == 4'b0110) begin
                        state <= 4'b0010;
                    end else if (in == 4'b0111) begin
                        state <= 4'b0011;
                    end else if (in == 4'b1000) begin
                        state <= 4'b0100;
                    end else if (in == 4'b1001) begin
                        state <= 4'b0101;
                    end else if (in == 4'b1010) begin
                        state <= 4'b0110;
                    end else if (in == 4'b1011) begin
                        state <= 4'b0111;
                    end else if (in == 4'b1100) begin
                        state <= 4'b1000;
                    end else if (in == 4'b1101) begin
                        state <= 4'b1001;
                    end else if (in == 4'b1110) begin