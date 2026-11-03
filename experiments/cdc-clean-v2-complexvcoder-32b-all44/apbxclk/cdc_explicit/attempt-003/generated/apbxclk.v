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

    // Internal signals
    reg [AW-1:0] s_req_addr_sync;
    reg s_req_write_sync;
    reg [DW-1:0] s_req_wdata_sync;
    reg [DW/8-1:0] s_req_wstrb_sync;
    reg [2:0] s_req_prot_sync;
    reg s_req_valid;
    reg s_req_ready;
    reg m_req_valid;
    reg m_req_ready;
    reg [DW-1:0] m_resp_rdata_sync;
    reg m_resp_slverr_sync;
    reg m_resp_valid;
    reg m_resp_ready;
    reg [DW-1:0] s_resp_rdata;
    reg s_resp_slverr;
    reg s_resp_valid;
    reg s_resp_ready;

    // S_APB to M_APB request synchronization
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_req_addr_sync <= 0;
            s_req_write_sync <= 0;
            s_req_wdata_sync <= 0;
            s_req_wstrb_sync <= 0;
            s_req_prot_sync <= 0;
            s_req_valid <= 0;
        end else begin
            if (s_req_ready) begin
                s_req_addr_sync <= S_APB_PADDR;
                s_req_write_sync <= S_APB_PWRITE;
                s_req_wdata_sync <= S_APB_PWDATA;
                s_req_wstrb_sync <= S_APB_PWSTRB;
                s_req_prot_sync <= S_APB_PPROT;
                s_req_valid <= S_APB_PSEL & S_APB_PENABLE;
            end
        end
    end

    // M_APB request generation
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_req_valid <= 0;
        end else begin
            if (s_req_valid && !m_req_valid) begin
                M_APB_PSEL <= s_req_valid;
                M_APB_PENABLE <= s_req_valid;
                m_req_valid <= s_req_valid;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
                m_req_valid <= 0;
            end
        end
    end

    // M_APB to S_APB response synchronization
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_resp_rdata_sync <= 0;
            m_resp_slverr_sync <= 0;
            m_resp_valid <= 0;
        end else begin
            if (M_APB_PREADY) begin
                m_resp_rdata_sync <= M_APB_PRDATA;
                m_resp_slverr_sync <= M_APB_PSLVERR;
                m_resp_valid <= 1;
            end else if (s_resp_ready) begin
                m_resp_valid <= 0;
            end
        end
    end

    // S_APB response generation
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
            s_resp_valid <= 0;
        end else begin
            if (m_resp_valid && !s_resp_valid) begin
                S_APB_PREADY <= 1;
                S_APB_PRDATA <= m_resp_rdata_sync;
                S_APB_PSLVERR <= m_resp_slverr_sync;
                s_resp_valid <= 1;
            end else if (s_req_ready) begin
                S_APB_PREADY <= 0;
                s_resp_valid <= 0;
            end
        end
    end

    // S_APB request ready signal
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_req_ready <= 0;
        end else begin
            s_req_ready <= !m_req_valid;
        end
    end

    // M_APB request ready signal
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_req_ready <= 0;
        end else begin
            m_req_ready <= !s_req_valid;
        end
    end

    // M_APB reset
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
        end else begin
            M_PRESETn <= 1;
        end
    end

    // S_APB outputs assignment
    assign S_APB_PADDR = s_req_addr_sync;
    assign S_APB_PWRITE = s_req_write_sync;
    assign S_APB_PWDATA = s_req_wdata_sync;
    assign S_APB_PWSTRB = s_req_wstrb_sync;
    assign S_APB_PPROT = s_req_prot_sync;

    // M_APB outputs assignment
    assign M_APB_PADDR = s_req_addr_sync;
    assign M_APB_PWRITE = s_req_write_sync;
    assign M_APB_PWDATA = s_req_wdata_sync;
    assign M_APB_PWSTRB = s_req_wstrb_sync;
    assign M_APB_PPROT = s_req_prot_sync;

    // S_APB response ready signal
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_resp_ready <= 0;
        end else begin
            s_resp_ready <= s_resp_valid;
        end
    end

endmodule
