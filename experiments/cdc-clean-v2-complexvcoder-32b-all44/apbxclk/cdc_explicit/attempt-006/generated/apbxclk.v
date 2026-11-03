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

    // Internal signals for synchronization
    reg [AW-1:0] s_addr_sync [1:0];
    reg s_write_sync [1:0];
    reg [DW-1:0] s_wdata_sync [1:0];
    reg [DW/8-1:0] s_wstrb_sync [1:0];
    reg [2:0] s_prot_sync [1:0];
    reg s_req_valid_sync [1:0];
    reg s_req_ready_sync [1:0];
    reg [DW-1:0] m_rdata_sync [1:0];
    reg m_slverr_sync [1:0];
    reg m_req_valid_sync [1:0];
    reg m_req_ready_sync [1:0];

    // Source domain logic
    reg [AW-1:0] s_addr;
    reg s_write;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0] s_prot;
    reg s_req_valid;
    reg s_req_ready;

    // Destination domain logic
    reg [AW-1:0] m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [DW/8-1:0] m_wstrb;
    reg [2:0] m_prot;
    reg [DW-1:0] m_rdata;
    reg m_slverr;
    reg m_req_valid;
    reg m_req_ready;

    // Synchronize source request to destination clock domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr_sync[0] <= 0;
            s_addr_sync[1] <= 0;
            s_write_sync[0] <= 0;
            s_write_sync[1] <= 0;
            s_wdata_sync[0] <= 0;
            s_wdata_sync[1] <= 0;
            s_wstrb_sync[0] <= 0;
            s_wstrb_sync[1] <= 0;
            s_prot_sync[0] <= 0;
            s_prot_sync[1] <= 0;
            s_req_valid_sync[0] <= 0;
            s_req_valid_sync[1] <= 0;
            s_req_ready_sync[0] <= 0;
            s_req_ready_sync[1] <= 0;
        end else begin
            s_addr_sync[0] <= S_APB_PADDR;
            s_addr_sync[1] <= s_addr_sync[0];
            s_write_sync[0] <= S_APB_PWRITE;
            s_write_sync[1] <= s_write_sync[0];
            s_wdata_sync[0] <= S_APB_PWDATA;
            s_wdata_sync[1] <= s_wdata_sync[0];
            s_wstrb_sync[0] <= S_APB_PWSTRB;
            s_wstrb_sync[1] <= s_wstrb_sync[0];
            s_prot_sync[0] <= S_APB_PPROT;
            s_prot_sync[1] <= s_prot_sync[0];
            s_req_valid_sync[0] <= S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY;
            s_req_valid_sync[1] <= s_req_valid_sync[0];
            s_req_ready_sync[0] <= m_req_ready;
            s_req_ready_sync[1] <= s_req_ready_sync[0];
        end
    end

    // Register the synchronized source request
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_addr <= 0;
            m_write <= 0;
            m_wdata <= 0;
            m_wstrb <= 0;
            m_prot <= 0;
            m_req_valid <= 0;
        end else begin
            if (s_req_valid_sync[1] && !m_req_valid) begin
                m_addr <= s_addr_sync[1];
                m_write <= s_write_sync[1];
                m_wdata <= s_wdata_sync[1];
                m_wstrb <= s_wstrb_sync[1];
                m_prot <= s_prot_sync[1];
                m_req_valid <= 1;
            end else if (M_APB_PREADY) begin
                m_req_valid <= 0;
            end
        end
    end

    // Drive destination interface
    assign M_APB_PSEL = m_req_valid;
    assign M_APB_PENABLE = m_req_valid;
    assign M_APB_PADDR = m_addr;
    assign M_APB_PWRITE = m_write;
    assign M_APB_PWDATA = m_wdata;
    assign M_APB_PWSTRB = m_wstrb;
    assign M_APB_PPROT = m_prot;

    // Synchronize destination response to source clock domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_rdata_sync[0] <= 0;
            m_rdata_sync[1] <= 0;
            m_slverr_sync[0] <= 0;
            m_slverr_sync[1] <= 0;
            m_req_ready_sync[0] <= 0;
            m_req_ready_sync[1] <= 0;
        end else begin
            m_rdata_sync[0] <= M_APB_PRDATA;
            m_rdata_sync[1] <= m_rdata_sync[0];
            m_slverr_sync[0] <= M_APB_PSLVERR;
            m_slverr_sync[1] <= m_slverr_sync[0];
            m_req_ready_sync[0] <= M_APB_PREADY;
            m_req_ready_sync[1] <= m_req_ready_sync[0];
        end
    end

    // Register the synchronized destination response
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_rdata <= 0;
            m_slverr <= 0;
            m_req_ready <= 0;
            S_APB_PREADY <= 0;
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
        end else begin
            if (m_req_ready_sync[1]) begin
                m_rdata <= m_rdata_sync[1];
                m_slverr <= m_slverr_sync[1];
                m_req_ready <= 1;
                S_APB_PREADY <= 1;
                S_APB_PRDATA <= m_rdata_sync[1];
                S_APB_PSLVERR <= m_slverr_sync[1];
            end else if (S_APB_PREADY) begin
                S_APB_PREADY <= 0;
                m_req_ready <= 0;
            end
        end
    end

    // Reset handling for destination clock domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn)
            M_PRESETn <= 0;
        else
            M_PRESETn <= 1;
    end

endmodule
