```verilog
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

	reg [AW-1:0]		addr_reg;
	reg [DW-1:0]		data_reg;
	reg [DW/8-1:0]	wstrb_reg;
	reg 			write_reg;
	reg 			sel_reg;
	reg 			enable_reg;
	reg 			prot_reg;
	reg 			slverr_reg;
	reg 			ready_reg;
	reg 			transfer_done;
	reg 			sync_req;
	reg 			sync_ack;
	reg 			sync_data;
	reg 			sync_err;
	reg 			sync_ready;
	reg 			sync_sel;
	reg 			sync_enable;
	reg 			sync_addr;
	reg 			sync_write;
	reg 			sync_wdata;
	reg 			sync_wstrb;
	reg 			sync_prot;
	reg 			sync_prdata;
	reg 			sync_pslverr;
	reg 			sync_pready;

	// Synchronous capture of source interface signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sync_req <= 1'b0;
			sync_ack <= 1'b0;
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
			sync_sel <= 1'b0;
			sync_enable <= 1'b0;
			sync_addr <= {AW{1'b0}};
			sync_write <= 1'b0;
			sync_wdata <= {DW{1'b0}};
			sync_wstrb <= {DW/8{1'b0}};
			sync_prot <= 3'b000;
			sync_prdata <= {DW{1'b0}};
			sync_pslverr <= 1'b0;
			sync_pready <= 1'b0;
		end
		else begin
			sync_req <= S_APB_PSEL & S_APB_PENABLE;
			sync_ack <= S_APB_PREADY;
			sync_data <= S_APB_PRDATA;
			sync_err <= S_APB_PSLVERR;
			sync_ready <= S_APB_PREADY;
			sync_sel <= S_APB_PSEL;
			sync_enable <= S_APB_PENABLE;
			sync_addr <= S_APB_PADDR;
			sync_write <= S_APB_PWRITE;
			sync_wdata <= S_APB_PWDATA;
			sync_wstrb <= S_APB_PWSTRB;
			sync_prot <= S_APB_PPROT;
			sync_prdata <= S_APB_PRDATA;
			sync_pslverr <= S_APB_PSLVERR;
			sync_pready <= S_APB_PREADY;
		end
	end

	// Synchronous capture of destination interface signals
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			transfer_done <= 1'b0;
		end
		else begin
			transfer_done <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sync_sel;
			M_APB_PENABLE <= sync_enable;
			M_APB_PADDR <= sync_addr;
			M_APB_PWRITE <= sync_write;
			M_APB_PWDATA <= sync_wdata;
			M_APB_PWSTRB <= sync_wstrb;
			M_APB_PPROT <= sync_prot;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_pready <= 1'b0;
			sync_prdata <= {DW{1'b0}};
			sync_pslverr <= 1'b0;
		end
		else begin
			sync_pready <= M_APB_PREADY;
			sync_prdata <= M_APB_PRDATA;
			sync_pslverr <= M_APB_PSLVERR;
		end
	end

	// Synchronous capture of source interface signals (for OPT_REGISTERED)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			addr_reg <= {AW{1'b0}};
			data_reg <= {DW{1'b0}};
			wstrb_reg <= {DW/8{1'b0}};
			write_reg <= 1'b0;
			sel_reg <= 1'b0;
			enable_reg <= 1'b0;
			prot_reg <= 3'b000;
			slverr_reg <= 1'b0;
			ready_reg <= 1'b0;
		end
		else begin
			addr_reg <= S_APB_PADDR;
			data_reg <= S_APB_PWDATA;
			wstrb_reg <= S_APB_PWSTRB;
			write_reg <= S_APB_PWRITE;
			sel_reg <= S_APB_PSEL;
			enable_reg <= S_APB_PENABLE;
			prot_reg <= S_APB_PPROT;
			slverr_reg <= S_APB_PSLVERR;
			ready_reg <= S_APB_PREADY;
		end
	end

	// Synchronous capture of destination interface signals (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			sync_data <= {DW{1'b0}};
			sync_err <= 1'b0;
			sync_ready <= 1'b0;
		end
		else begin
			sync_data <= M_APB_PRDATA;
			sync_err <= M_APB_PSLVERR;
			sync_ready <= M_APB_PREADY;
		end
	end

	// Cross-domain request generation (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= 3'b000;
			M_PRESETn <= 1'b0;
		end
		else begin
			M_APB_PSEL <= sel_reg;
			M_APB_PENABLE <= enable_reg;
			M_APB_PADDR <= addr_reg;
			M_APB_PWRITE <= write_reg;
			M_APB_PWDATA <= data_reg;
			M_APB_PWSTRB <= wstrb_reg;
			M_APB_PPROT <= prot_reg;
			M_PRESETn <= 1'b1;
		end
	end

	// Cross-domain response capture (for OPT_REGISTERED)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
		