module apbxclk #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        parameter [0:0] OPT_REGISTERED = 1'b0,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH
    ) (
        input   wire            S_APB_PCLK, S_PRESETn,
        input   wire            S_APB_PSEL,
        input   wire            S_APB_PENABLE,
        output  reg             S_APB_PREADY,
        input   wire  [AW-1:0]  S_APB_PADDR,
        input   wire            S_APB_PWRITE,
        input   wire  [DW-1:0]  S_APB_PWDATA,
        input   wire  [DW/8-1:0] S_APB_PWSTRB,
        input   wire  [2:0]     S_APB_PPROT,
        output  wire  [DW-1:0]  S_APB_PRDATA,
        output  wire            S_APB_PSLVERR,
        input   wire            M_APB_PCLK,
        output  reg             M_PRESETn,
        output  reg             M_APB_PSEL,
        output  reg             M_APB_PENABLE,
        input   wire            M_APB_PREADY,
        output  wire  [AW-1:0]  M_APB_PADDR,
        output  wire            M_APB_PWRITE,
        output  wire  [DW-1:0]  M_APB_PWDATA,
        output  wire  [DW/8-1:0] M_APB_PWSTRB,
        output  wire  [2:0]     M_APB_PPROT,
        input   wire  [DW-1:0]  M_APB_PRDATA,
        input   wire            M_APB_PSLVERR
    );

    // Internal signals
    reg [AW-1:0] m_apb_paddr_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg          m_apb_pwrite_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0]    m_apb_pprot_reg;
    reg [DW-1:0] s_apb_prdata_reg;
    reg          s_apb_pslverr_reg;
    reg          m_apb_pready_sync;
    reg          s_apb_pready_sync;

    // Synchronizers
    synchronizer sync_psel (
        .in(S_APB_PSEL),
        .out(M_APB_PSEL)
    );

    synchronizer sync_penable (
        .in(S_APB_PENABLE),
        .out(M_APB_PENABLE)
    );

    synchronizer sync_pready (
        .in(M_APB_PREADY),
        .out(S_APB_PREADY)
    );

    // S_APB side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            s_apb_prdata_reg <= 0;
            s_apb_pslverr_reg <= 0;
        end else begin
            if (M_APB_PREADY) begin
                S_APB_PREADY <= 1;
                s_apb_prdata_reg <= M_APB_PRDATA;
                s_apb_pslverr_reg <= M_APB_PSLVERR;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    // M_APB side logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
            m_apb_paddr_reg <= 0;
            m_apb_pwdata_reg <= 0;
            m_apb_pwrite_reg <= 0;
            m_apb_pwstrb_reg <= 0;
            m_apb_pprot_reg <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
        end else begin
            M_PRESETn <= 1;
            if (S_APB_PSEL && S_APB_PENABLE && !M_APB_PSEL) begin
                m_apb_paddr_reg <= S_APB_PADDR;
                m_apb_pwdata_reg <= S_APB_PWDATA;
                m_apb_pwrite_reg <= S_APB_PWRITE;
                m_apb_pwstrb_reg <= S_APB_PWSTRB;
                m_apb_pprot_reg <= S_APB_PPROT;
                M_APB_PSEL <= 1;
                M_APB_PENABLE <= 1;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
            end
        end
    end

    // Assignments
    assign M_APB_PADDR = m_apb_paddr_reg;
    assign M_APB_PWDATA = m_apb_pwdata_reg;
    assign M_APB_PWRITE = m_apb_pwrite_reg;
    assign M_APB_PWSTRB = m_apb_pwstrb_reg;
    assign M_APB_PPROT = m_apb_pprot_reg;
    assign S_APB_PRDATA = s_apb_prdata_reg;
    assign S_APB_PSLVERR = s_apb_pslverr_reg;

endmodule

module synchronizer (
        input   wire    in,
        output  reg     out
    );

    reg sync_reg1, sync_reg2;

    always @(posedge M_APB_PCLK) begin
        sync_reg1 <= in;
        sync_reg2 <= sync_reg1;
        out <= sync_reg2;
    end

endmodule
