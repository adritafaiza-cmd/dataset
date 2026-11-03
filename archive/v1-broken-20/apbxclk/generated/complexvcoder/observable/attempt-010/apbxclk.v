module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    input wire S_APB_PCLK, S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [DW/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output wire [AW-1:0] M_APB_PADDR,
    output wire M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [DW/8-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    reg [AW-1:0] m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [DW/8-1:0] m_wstrb;
    reg [2:0] m_prot;
    reg m_psel;
    reg m_penable;
    wire m_pready;
    wire [DW-1:0] m_prdata;
    wire m_pslverr;

    reg [AW-1:0] s_addr;
    reg s_write;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0] s_prot;
    reg s_psel;
    reg s_penable;
    wire s_pready;
    wire [DW-1:0] s_prdata;
    wire s_pslverr;

    // Clock domain crossing for slave to master
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr <= 0;
            s_write <= 0;
            s_wdata <= 0;
            s_wstrb <= 0;
            s_prot <= 0;
            s_psel <= 0;
            s_penable <= 0;
        end else begin
            s_addr <= S_APB_PADDR;
            s_write <= S_APB_PWRITE;
            s_wdata <= S_APB_PWDATA;
            s_wstrb <= S_APB_PWSTRB;
            s_prot <= S_APB_PPROT;
            s_psel <= S_APB_PSEL;
            s_penable <= S_APB_PENABLE;
        end
    end

    // Clock domain crossing for master to slave
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_addr <= 0;
            m_write <= 0;
            m_wdata <= 0;
            m_wstrb <= 0;
            m_prot <= 0;
            m_psel <= 0;
            m_penable <= 0;
        end else begin
            m_addr <= s_addr;
            m_write <= s_write;
            m_wdata <= s_wdata;
            m_wstrb <= s_wstrb;
            m_prot <= s_prot;
            m_psel <= s_psel;
            m_penable <= s_penable;
        end
    end

    // Drive the master signals
    assign M_APB_PADDR = m_addr;
    assign M_APB_PWRITE = m_write;
    assign M_APB_PWDATA = m_wdata;
    assign M_APB_PWSTRB = m_wstrb;
    assign M_APB_PPROT = m_prot;
    assign M_APB_PSEL = m_psel;
    assign M_APB_PENABLE = m_penable;

    // Drive the slave signals
    assign S_APB_PREADY = m_pready;
    assign S_APB_PRDATA = m_prdata;
    assign S_APB_PSLVERR = m_pslverr;

endmodule
