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

    // Internal signals for S_APB to M_APB crossing
    reg [AW-1:0] s_apb_req_addr_reg;
    reg s_apb_req_write_reg;
    reg [DW-1:0] s_apb_req_wdata_reg;
    reg [DW/8-1:0] s_apb_req_wstrb_reg;
    reg [2:0] s_apb_req_prot_reg;
    reg s_apb_req_valid_reg;
    reg s_apb_req_ready_reg;

    // Internal signals for M_APB to S_APB crossing
    reg [DW-1:0] m_apb_rsp_rdata_reg;
    reg m_apb_rsp_slverr_reg;
    reg m_apb_req_ready_reg;

    // Cross-domain synchronization for S_APB to M_APB
    reg [AW-1:0] s_apb_req_addr_sync;
    reg s_apb_req_write_sync;
    reg [DW-1:0] s_apb_req_wdata_sync;
    reg [DW/8-1:0] s_apb_req_wstrb_sync;
    reg [2:0] s_apb_req_prot_sync;
    reg s_apb_req_valid_sync;
    reg s_apb_req_ready_sync;

    // Cross-domain synchronization for M_APB to S_APB
    reg [DW-1:0] m_apb_rsp_rdata_sync;
    reg m_apb_rsp_slverr_sync;
    reg m_apb_req_ready_sync;

    // S_APB to M_APB crossing
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_req_addr_sync <= 0;
            s_apb_req_write_sync <= 0;
            s_apb_req_wdata_sync <= 0;
            s_apb_req_wstrb_sync <= 0;
            s_apb_req_prot_sync <= 0;
            s_apb_req_valid_sync <= 0;
            s_apb_req_ready_sync <= 0;
        end else begin
            s_apb_req_addr_sync <= s_apb_req_addr_reg;
            s_apb_req_write_sync <= s_apb_req_write_reg;
            s_apb_req_wdata_sync <= s_apb_req_wdata_reg;
            s_apb_req_wstrb_sync <= s_apb_req_wstrb_reg;
            s_apb_req_prot_sync <= s_apb_req_prot_reg;
            s_apb_req_valid_sync <= s_apb_req_valid_reg;
            s_apb_req_ready_sync <= s_apb_req_ready_reg;
        end
    end

    // M_APB to S_APB crossing
    always @(posedge S_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_apb_rsp_rdata_sync <= 0;
            m_apb_rsp_slverr_sync <= 0;
            m_apb_req_ready_sync <= 0;
        end else begin
            m_apb_rsp_rdata_sync <= m_apb_rsp_rdata_reg;
            m_apb_rsp_slverr_sync <= m_apb_rsp_slverr_reg;
            m_apb_req_ready_sync <= m_apb_req_ready_reg;
        end
    end

    // Registering the crossing signals if OPT_REGISTERED is set
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_req_valid_reg <= 0;
            s_apb_req_ready_reg <= 0;
        end else if (OPT_REGISTERED) begin
            s_apb_req_valid_reg <= s_apb_req_valid_sync;
            s_apb_req_ready_reg <= s_apb_req_ready_sync;
        end else begin
            s_apb_req_valid_reg <= s_apb_req_valid_sync;
            s_apb_req_ready_reg <= s_apb_req_ready_sync;
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_apb_rsp_rdata_reg <= 0;
            m_apb_rsp_slverr_reg <= 0;
            m_apb_req_ready_reg <= 0;
        end else if (OPT_REGISTERED) begin
            m_apb_rsp_rdata_reg <= m_apb_rsp_rdata_sync;
            m_apb_rsp_slverr_reg <= m_apb_rsp_slverr_sync;
            m_apb_req_ready_reg <= m_apb_req_ready_sync;
        end else begin
            m_apb_rsp_rdata_reg <= m_apb_rsp_rdata_sync;
            m_apb_rsp_slverr_reg <= m_apb_rsp_slverr_sync;
            m_apb_req_ready_reg <= m_apb_req_ready_sync;
        end
    end

    // S_APB side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
        end else begin
            if (s_apb_req_ready_reg) begin
                S_APB_PREADY <= 1;
                S_APB_PRDATA <= m_apb_rsp_rdata_reg;
                S_APB_PSLVERR <= m_apb_rsp_slverr_reg;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_req_valid_reg <= 0;
            s_apb_req_addr_reg <= 0;
            s_apb_req_write_reg <= 0;
            s_apb_req_wdata_reg <= 0;
            s_apb_req_wstrb_reg <= 0;
            s_apb_req_prot_reg <= 0;
            s_apb_req_ready_reg <= 0;
        end else if (S_APB_PSEL && S_APB_PENABLE && !s_apb_req_valid_reg) begin
            s_apb_req_valid_reg <= 1;
            s_apb_req_addr_reg <= S_APB_PADDR;
            s_apb_req_write_reg <= S_APB_PWRITE;
            s_apb_req_wdata_reg <= S_APB_PWDATA;
            s_apb_req_wstrb_reg <= S_APB_PWSTRB;
            s_apb_req_prot_reg <= S_APB_PPROT;
            s_apb_req_ready_reg <= 0;
        end else if (s_apb_req_ready_reg) begin
            s_apb_req_valid_reg <= 0;
        end
    end

    // M_APB side logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            M_APB_PADDR <= 0;
            M_APB_PWRITE <= 0;
            M_APB_PWDATA <= 0;
            M_APB_PWSTRB <= 0;
            M_APB_PPROT <= 0;
            m_apb_req_ready_reg <= 0;
        end else begin
            M_PRESETn <= 1;
            if (s_apb_req_valid_sync && !m_apb_req_ready_reg) begin
                M_APB_PSEL <= 1;
                M_APB_PADDR <= s_apb_req_addr_sync;
                M_APB_PWRITE <= s_apb_req_write_sync;
                M_APB_PWDATA <= s_apb_req_wdata_sync;
                M_APB_PWSTRB <= s_apb_req_wstrb_sync;
                M_APB_PPROT <= s_apb_req_prot_sync;
                M_APB_PENABLE <= 1;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
                m_apb_req_ready_reg <= 1;
            end else begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
            end
        end
    end

endmodule
