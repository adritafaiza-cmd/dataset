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

    // Internal signals
    reg [AW-1:0] s_addr;
    reg          s_write;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0]    s_pprot;

    // Synchronization signals
    reg          s_req;
    reg          m_req_sync1;
    reg          m_req_sync2;
    reg          m_req_sync3;
    reg          m_req_sync4;
    reg          m_req_pending;
    reg          m_req_valid;

    reg          m_done;
    reg          s_done_sync1;
    reg          s_done_sync2;
    reg          s_done_sync3;
    reg          s_done_sync4;
    reg          s_done_pending;
    reg          s_done_valid;

    // Reset synchronization
    reg          m_reset_sync1;
    reg          m_reset_sync2;
    reg          m_reset_sync3;
    reg          m_reset_sync4;
    reg          m_reset_active;

    // M-side state
    reg          m_fsm_idle;
    reg          m_fsm_setup;
    reg          m_fsm_access;

    // M-side output registers
    reg [AW-1:0] m_addr_reg;
    reg          m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg [2:0]    m_pprot_reg;

    // S-side response registers
    reg [DW-1:0] s_rdata_reg;
    reg          s_pslverr_reg;

    // M-side response capture
    reg [DW-1:0] m_rdata_sync1;
    reg [DW-1:0] m_rdata_sync2;
    reg [DW-1:0] m_rdata_sync3;
    reg [DW-1:0] m_rdata_sync4;
    reg [DW-1:0] m_rdata_captured;

    reg          m_pslverr_sync1;
    reg          m_pslverr_sync2;
    reg          m_pslverr_sync3;
    reg          m_pslverr_sync4;
    reg          m_pslverr_captured;

    // S-side response sync
    reg [DW-1:0] s_rdata_out_sync1;
    reg [DW-1:0] s_rdata_out_sync2;
    reg [DW-1:0] s_rdata_out_sync3;
    reg [DW-1:0] s_rdata_out_sync4;
    reg [DW-1:0] s_rdata_out;

    reg          s_pslverr_out_sync1;
    reg          s_pslverr_out_sync2;
    reg          s_pslverr_out_sync3;
    reg          s_pslverr_out_sync4;
    reg          s_pslverr_out;

    // S-side request capture
    reg          s_req_pending;
    reg          s_req_valid;

    // M-side request sync
    reg          m_req_sync1_r;
    reg          m_req_sync2_r;
    reg          m_req_sync3_r;
    reg          m_req_sync4_r;

    // S-side done sync
    reg          s_done_sync1_r;
    reg          s_done_sync2_r;
    reg          s_done_sync3_r;
    reg          s_done_sync4_r;

    // M-side reset sync
    reg          m_reset_sync1_r;
    reg          m_reset_sync2_r;
    reg          m_reset_sync3_r;
    reg          m_reset_sync4_r;

    // M-side response sync
    reg [DW-1:0] m_rdata_sync1_r;
    reg [DW-1:0] m_rdata_sync2_r;
    reg [DW-1:0] m_rdata_sync3_r;
    reg [DW-1:0] m_rdata_sync4_r;

    reg          m_pslverr_sync1_r;
    reg          m_pslverr_sync2_r;
    reg          m_pslverr_sync3_r;
    reg          m_pslverr_sync4_r;

    // S-side response out sync
    reg [DW-1:0] s_rdata_out_sync1_r;
    reg [DW-1:0] s_rdata_out_sync2_r;
    reg [DW-1:0] s_rdata_out_sync3_r;
    reg [DW-1:0] s_rdata_out_sync4_r;

    reg          s_pslverr_out_sync1_r;
    reg          s_pslverr_out_sync2_r;
    reg          s_pslverr_out_sync3_r;
    reg          s_pslverr_out_sync4_r;

    // S-side request sync
    reg          s_req_sync1_r;
    reg          s_req_sync2_r;
    reg          s_req_sync3_r;
    reg          s_req_sync4_r;

    // M-side done sync
    reg          m_done_sync1_r;
    reg          m_done_sync2_r;
    reg          m_done_sync3_r;
    reg          m_done_sync4_r;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r2;
    reg          s_done_sync2_r2;
    reg          s_done_sync3_r2;
    reg          s_done_sync4_r2;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r2;
    reg          m_req_sync2_r2;
    reg          m_req_sync3_r2;
    reg          m_req_sync4_r2;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r2;
    reg          s_req_sync2_r2;
    reg          s_req_sync3_r2;
    reg          s_req_sync4_r2;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r2;
    reg          m_done_sync2_r2;
    reg          m_done_sync3_r2;
    reg          m_done_sync4_r2;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r2;
    reg [DW-1:0] s_rdata_sync2_r2;
    reg [DW-1:0] s_rdata_sync3_r2;
    reg [DW-1:0] s_rdata_sync4_r2;

    reg          s_pslverr_sync1_r2;
    reg          s_pslverr_sync2_r2;
    reg          s_pslverr_sync3_r2;
    reg          s_pslverr_sync4_r2;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r2;
    reg [DW-1:0] m_rdata_sync2_r2;
    reg [DW-1:0] m_rdata_sync3_r2;
    reg [DW-1:0] m_rdata_sync4_r2;

    reg          m_pslverr_sync1_r2;
    reg          m_pslverr_sync2_r2;
    reg          m_pslverr_sync3_r2;
    reg          m_pslverr_sync4_r2;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r3;
    reg          s_req_sync2_r3;
    reg          s_req_sync3_r3;
    reg          s_req_sync4_r3;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r3;
    reg          m_done_sync2_r3;
    reg          m_done_sync3_r3;
    reg          m_done_sync4_r3;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r3;
    reg          s_done_sync2_r3;
    reg          s_done_sync3_r3;
    reg          s_done_sync4_r3;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r3;
    reg          m_req_sync2_r3;
    reg          m_req_sync3_r3;
    reg          m_req_sync4_r3;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r3;
    reg [DW-1:0] s_rdata_sync2_r3;
    reg [DW-1:0] s_rdata_sync3_r3;
    reg [DW-1:0] s_rdata_sync4_r3;

    reg          s_pslverr_sync1_r3;
    reg          s_pslverr_sync2_r3;
    reg          s_pslverr_sync3_r3;
    reg          s_pslverr_sync4_r3;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r3;
    reg [DW-1:0] m_rdata_sync2_r3;
    reg [DW-1:0] m_rdata_sync3_r3;
    reg [DW-1:0] m_rdata_sync4_r3;

    reg          m_pslverr_sync1_r3;
    reg          m_pslverr_sync2_r3;
    reg          m_pslverr_sync3_r3;
    reg          m_pslverr_sync4_r3;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r4;
    reg          s_req_sync2_r4;
    reg          s_req_sync3_r4;
    reg          s_req_sync4_r4;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r4;
    reg          m_done_sync2_r4;
    reg          m_done_sync3_r4;
    reg          m_done_sync4_r4;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r4;
    reg          s_done_sync2_r4;
    reg          s_done_sync3_r4;
    reg          s_done_sync4_r4;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r4;
    reg          m_req_sync2_r4;
    reg          m_req_sync3_r4;
    reg          m_req_sync4_r4;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r4;
    reg [DW-1:0] s_rdata_sync2_r4;
    reg [DW-1:0] s_rdata_sync3_r4;
    reg [DW-1:0] s_rdata_sync4_r4;

    reg          s_pslverr_sync1_r4;
    reg          s_pslverr_sync2_r4;
    reg          s_pslverr_sync3_r4;
    reg          s_pslverr_sync4_r4;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r4;
    reg [DW-1:0] m_rdata_sync2_r4;
    reg [DW-1:0] m_rdata_sync3_r4;
    reg [DW-1:0] m_rdata_sync4_r4;

    reg          m_pslverr_sync1_r4;
    reg          m_pslverr_sync2_r4;
    reg          m_pslverr_sync3_r4;
    reg          m_pslverr_sync4_r4;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r5;
    reg          s_req_sync2_r5;
    reg          s_req_sync3_r5;
    reg          s_req_sync4_r5;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r5;
    reg          m_done_sync2_r5;
    reg          m_done_sync3_r5;
    reg          m_done_sync4_r5;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r5;
    reg          s_done_sync2_r5;
    reg          s_done_sync3_r5;
    reg          s_done_sync4_r5;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r5;
    reg          m_req_sync2_r5;
    reg          m_req_sync3_r5;
    reg          m_req_sync4_r5;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r5;
    reg [DW-1:0] s_rdata_sync2_r5;
    reg [DW-1:0] s_rdata_sync3_r5;
    reg [DW-1:0] s_rdata_sync4_r5;

    reg          s_pslverr_sync1_r5;
    reg          s_pslverr_sync2_r5;
    reg          s_pslverr_sync3_r5;
    reg          s_pslverr_sync4_r5;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r5;
    reg [DW-1:0] m_rdata_sync2_r5;
    reg [DW-1:0] m_rdata_sync3_r5;
    reg [DW-1:0] m_rdata_sync4_r5;

    reg          m_pslverr_sync1_r5;
    reg          m_pslverr_sync2_r5;
    reg          m_pslverr_sync3_r5;
    reg          m_pslverr_sync4_r5;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r6;
    reg          s_req_sync2_r6;
    reg          s_req_sync3_r6;
    reg          s_req_sync4_r6;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r6;
    reg          m_done_sync2_r6;
    reg          m_done_sync3_r6;
    reg          m_done_sync4_r6;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r6;
    reg          s_done_sync2_r6;
    reg          s_done_sync3_r6;
    reg          s_done_sync4_r6;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r6;
    reg          m_req_sync2_r6;
    reg          m_req_sync3_r6;
    reg          m_req_sync4_r6;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r6;
    reg [DW-1:0] s_rdata_sync2_r6;
    reg [DW-1:0] s_rdata_sync3_r6;
    reg [DW-1:0] s_rdata_sync4_r6;

    reg          s_pslverr_sync1_r6;
    reg          s_pslverr_sync2_r6;
    reg          s_pslverr_sync3_r6;
    reg          s_pslverr_sync4_r6;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r6;
    reg [DW-1:0] m_rdata_sync2_r6;
    reg [DW-1:0] m_rdata_sync3_r6;
    reg [DW-1:0] m_rdata_sync4_r6;

    reg          m_pslverr_sync1_r6;
    reg          m_pslverr_sync2_r6;
    reg          m_pslverr_sync3_r6;
    reg          m_pslverr_sync4_r6;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r7;
    reg          s_req_sync2_r7;
    reg          s_req_sync3_r7;
    reg          s_req_sync4_r7;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r7;
    reg          m_done_sync2_r7;
    reg          m_done_sync3_r7;
    reg          m_done_sync4_r7;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r7;
    reg          s_done_sync2_r7;
    reg          s_done_sync3_r7;
    reg          s_done_sync4_r7;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r7;
    reg          m_req_sync2_r7;
    reg          m_req_sync3_r7;
    reg          m_req_sync4_r7;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r7;
    reg [DW-1:0] s_rdata_sync2_r7;
    reg [DW-1:0] s_rdata_sync3_r7;
    reg [DW-1:0] s_rdata_sync4_r7;

    reg          s_pslverr_sync1_r7;
    reg          s_pslverr_sync2_r7;
    reg          s_pslverr_sync3_r7;
    reg          s_pslverr_sync4_r7;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r7;
    reg [DW-1:0] m_rdata_sync2_r7;
    reg [DW-1:0] m_rdata_sync3_r7;
    reg [DW-1:0] m_rdata_sync4_r7;

    reg          m_pslverr_sync1_r7;
    reg          m_pslverr_sync2_r7;
    reg          m_pslverr_sync3_r7;
    reg          m_pslverr_sync4_r7;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r8;
    reg          s_req_sync2_r8;
    reg          s_req_sync3_r8;
    reg          s_req_sync4_r8;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r8;
    reg          m_done_sync2_r8;
    reg          m_done_sync3_r8;
    reg          m_done_sync4_r8;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r8;
    reg          s_done_sync2_r8;
    reg          s_done_sync3_r8;
    reg          s_done_sync4_r8;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r8;
    reg          m_req_sync2_r8;
    reg          m_req_sync3_r8;
    reg          m_req_sync4_r8;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r8;
    reg [DW-1:0] s_rdata_sync2_r8;
    reg [DW-1:0] s_rdata_sync3_r8;
    reg [DW-1:0] s_rdata_sync4_r8;

    reg          s_pslverr_sync1_r8;
    reg          s_pslverr_sync2_r8;
    reg          s_pslverr_sync3_r8;
    reg          s_pslverr_sync4_r8;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r8;
    reg [DW-1:0] m_rdata_sync2_r8;
    reg [DW-1:0] m_rdata_sync3_r8;
    reg [DW-1:0] m_rdata_sync4_r8;

    reg          m_pslverr_sync1_r8;
    reg          m_pslverr_sync2_r8;
    reg          m_pslverr_sync3_r8;
    reg          m_pslverr_sync4_r8;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r9;
    reg          s_req_sync2_r9;
    reg          s_req_sync3_r9;
    reg          s_req_sync4_r9;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r9;
    reg          m_done_sync2_r9;
    reg          m_done_sync3_r9;
    reg          m_done_sync4_r9;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r9;
    reg          s_done_sync2_r9;
    reg          s_done_sync3_r9;
    reg          s_done_sync4_r9;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r9;
    reg          m_req_sync2_r9;
    reg          m_req_sync3_r9;
    reg          m_req_sync4_r9;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r9;
    reg [DW-1:0] s_rdata_sync2_r9;
    reg [DW-1:0] s_rdata_sync3_r9;
    reg [DW-1:0] s_rdata_sync4_r9;

    reg          s_pslverr_sync1_r9;
    reg          s_pslverr_sync2_r9;
    reg          s_pslverr_sync3_r9;
    reg          s_pslverr_sync4_r9;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r9;
    reg [DW-1:0] m_rdata_sync2_r9;
    reg [DW-1:0] m_rdata_sync3_r9;
    reg [DW-1:0] m_rdata_sync4_r9;

    reg          m_pslverr_sync1_r9;
    reg          m_pslverr_sync2_r9;
    reg          m_pslverr_sync3_r9;
    reg          m_pslverr_sync4_r9;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r10;
    reg          s_req_sync2_r10;
    reg          s_req_sync3_r10;
    reg          s_req_sync4_r10;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r10;
    reg          m_done_sync2_r10;
    reg          m_done_sync3_r10;
    reg          m_done_sync4_r10;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r10;
    reg          s_done_sync2_r10;
    reg          s_done_sync3_r10;
    reg          s_done_sync4_r10;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r10;
    reg          m_req_sync2_r10;
    reg          m_req_sync3_r10;
    reg          m_req_sync4_r10;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r10;
    reg [DW-1:0] s_rdata_sync2_r10;
    reg [DW-1:0] s_rdata_sync3_r10;
    reg [DW-1:0] s_rdata_sync4_r10;

    reg          s_pslverr_sync1_r10;
    reg          s_pslverr_sync2_r10;
    reg          s_pslverr_sync3_r10;
    reg          s_pslverr_sync4_r10;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r10;
    reg [DW-1:0] m_rdata_sync2_r10;
    reg [DW-1:0] m_rdata_sync3_r10;
    reg [DW-1:0] m_rdata_sync4_r10;

    reg          m_pslverr_sync1_r10;
    reg          m_pslverr_sync2_r10;
    reg          m_pslverr_sync3_r10;
    reg          m_pslverr_sync4_r10;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r11;
    reg          s_req_sync2_r11;
    reg          s_req_sync3_r11;
    reg          s_req_sync4_r11;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r11;
    reg          m_done_sync2_r11;
    reg          m_done_sync3_r11;
    reg          m_done_sync4_r11;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r11;
    reg          s_done_sync2_r11;
    reg          s_done_sync3_r11;
    reg          s_done_sync4_r11;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r11;
    reg          m_req_sync2_r11;
    reg          m_req_sync3_r11;
    reg          m_req_sync4_r11;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r11;
    reg [DW-1:0] s_rdata_sync2_r11;
    reg [DW-1:0] s_rdata_sync3_r11;
    reg [DW-1:0] s_rdata_sync4_r11;

    reg          s_pslverr_sync1_r11;
    reg          s_pslverr_sync2_r11;
    reg          s_pslverr_sync3_r11;
    reg          s_pslverr_sync4_r11;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r11;
    reg [DW-1:0] m_rdata_sync2_r11;
    reg [DW-1:0] m_rdata_sync3_r11;
    reg [DW-1:0] m_rdata_sync4_r11;

    reg          m_pslverr_sync1_r11;
    reg          m_pslverr_sync2_r11;
    reg          m_pslverr_sync3_r11;
    reg          m_pslverr_sync4_r11;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r12;
    reg          s_req_sync2_r12;
    reg          s_req_sync3_r12;
    reg          s_req_sync4_r12;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r12;
    reg          m_done_sync2_r12;
    reg          m_done_sync3_r12;
    reg          m_done_sync4_r12;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r12;
    reg          s_done_sync2_r12;
    reg          s_done_sync3_r12;
    reg          s_done_sync4_r12;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r12;
    reg          m_req_sync2_r12;
    reg          m_req_sync3_r12;
    reg          m_req_sync4_r12;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r12;
    reg [DW-1:0] s_rdata_sync2_r12;
    reg [DW-1:0] s_rdata_sync3_r12;
    reg [DW-1:0] s_rdata_sync4_r12;

    reg          s_pslverr_sync1_r12;
    reg          s_pslverr_sync2_r12;
    reg          s_pslverr_sync3_r12;
    reg          s_pslverr_sync4_r12;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r12;
    reg [DW-1:0] m_rdata_sync2_r12;
    reg [DW-1:0] m_rdata_sync3_r12;
    reg [DW-1:0] m_rdata_sync4_r12;

    reg          m_pslverr_sync1_r12;
    reg          m_pslverr_sync2_r12;
    reg          m_pslverr_sync3_r12;
    reg          m_pslverr_sync4_r12;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r13;
    reg          s_req_sync2_r13;
    reg          s_req_sync3_r13;
    reg          s_req_sync4_r13;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r13;
    reg          m_done_sync2_r13;
    reg          m_done_sync3_r13;
    reg          m_done_sync4_r13;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r13;
    reg          s_done_sync2_r13;
    reg          s_done_sync3_r13;
    reg          s_done_sync4_r13;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r13;
    reg          m_req_sync2_r13;
    reg          m_req_sync3_r13;
    reg          m_req_sync4_r13;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r13;
    reg [DW-1:0] s_rdata_sync2_r13;
    reg [DW-1:0] s_rdata_sync3_r13;
    reg [DW-1:0] s_rdata_sync4_r13;

    reg          s_pslverr_sync1_r13;
    reg          s_pslverr_sync2_r13;
    reg          s_pslverr_sync3_r13;
    reg          s_pslverr_sync4_r13;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r13;
    reg [DW-1:0] m_rdata_sync2_r13;
    reg [DW-1:0] m_rdata_sync3_r13;
    reg [DW-1:0] m_rdata_sync4_r13;

    reg          m_pslverr_sync1_r13;
    reg          m_pslverr_sync2_r13;
    reg          m_pslverr_sync3_r13;
    reg          m_pslverr_sync4_r13;

    // S-side request sync (for S domain)
    reg          s_req_sync1_r14;
    reg          s_req_sync2_r14;
    reg          s_req_sync3_r14;
    reg          s_req_sync4_r14;

    // M-side done sync (for M domain)
    reg          m_done_sync1_r14;
    reg          m_done_sync2_r14;
    reg          m_done_sync3_r14;
    reg          m_done_sync4_r14;

    // S-side done sync (for S domain)
    reg          s_done_sync1_r14;
    reg          s_done_sync2_r14;
    reg          s_done_sync3_r14;
    reg          s_done_sync4_r14;

    // M-side request sync (for M domain)
    reg          m_req_sync1_r14;
    reg          m_req_sync2_r14;
    reg          m_req_sync3_r14;
    reg          m_req_sync4_r14;

    // S-side response sync (for S domain)
    reg [DW-1:0] s_rdata_sync1_r14;
    reg [DW-1:0] s_rdata_sync2_r14;
    reg [DW-1:0] s_rdata_sync3_r14;
    reg [DW-1:0] s_rdata_sync4_r14;

    reg          s_pslverr_sync1_r14;
    reg          s_pslverr_sync2_r14;
    reg          s_pslverr_sync3_r14;
    reg          s_pslverr_sync4_r14;

    // M-side response sync (for M domain)
    reg [DW-1:0] m_rdata_sync1_r14;
    reg [DW-1: