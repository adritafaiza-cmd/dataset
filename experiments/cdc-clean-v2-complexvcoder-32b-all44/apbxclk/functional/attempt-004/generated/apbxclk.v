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
    reg s_apb_pready_sync;
    reg m_apb_pready_sync;
    reg s_apb_pready_ff;
    reg m_apb_pready_ff;
    reg [DW-1:0] s_apb_prdata_sync;
    reg s_apb_pslverr_sync;
    reg [DW-1:0] s_apb_prdata_ff;
    reg s_apb_pslverr_ff;
    reg m_apb_psel_ff;
    reg m_apb_penable_ff;
    reg [AW-1:0] m_apb_paddr_ff;
    reg m_apb_pwrite_ff;
    reg [DW-1:0] m_apb_pwdata_ff;
    reg [DW/8-1:0] m_apb_pwstrb_ff;
    reg [2:0] m_apb_pprot_ff;
    reg s_apb_req_valid;
    reg m_apb_req_valid;
    reg s_apb_req_ready;
    reg m_apb_req_ready;

    // Cross clock domain synchronization for M_APB_PREADY
    sync_cell sync_m_apb_pready (
        .clk(S_APB_PCLK),
        .reset(~S_PRESETn),
        .din(M_APB_PREADY),
        .dout(s_apb_pready_sync)
    );

    // Cross clock domain synchronization for S_APB_PREADY
    sync_cell sync_s_apb_pready (
        .clk(M_APB_PCLK),
        .reset(~M_PRESETn),
        .din(S_APB_PREADY),
        .dout(m_apb_pready_sync)
    );

    // S_APB side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (~S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_prdata_ff <= {DW{1'b0}};
            s_apb_pslverr_ff <= 1'b0;
            s_apb_req_valid <= 1'b0;
        end else begin
            if (s_apb_req_ready && S_APB_PSEL && S_APB_PENABLE) begin
                s_apb_req_valid <= 1'b1;
            end

            if (s_apb_pready_sync) begin
                S_APB_PREADY <= 1'b1;
                s_apb_prdata_ff <= s_apb_prdata_sync;
                s_apb_pslverr_ff <= s_apb_pslverr_sync;
                s_apb_req_valid <= 1'b0;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    // M_APB side logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (~M_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_apb_req_valid <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            if (m_apb_req_ready && s_apb_req_valid) begin
                M_APB_PSEL <= S_APB_PSEL;
                M_APB_PENABLE <= S_APB_PENABLE;
                M_APB_PADDR <= S_APB_PADDR;
                M_APB_PWRITE <= S_APB_PWRITE;
                M_APB_PWDATA <= S_APB_PWDATA;
                M_APB_PWSTRB <= S_APB_PWSTRB;
                M_APB_PPROT <= S_APB_PPROT;
                m_apb_req_valid <= 1'b1;
            end

            if (m_apb_pready_sync) begin
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
                m_apb_req_valid <= 1'b0;
            end
        end
    end

    // Ready signals
    always @(*) begin
        s_apb_req_ready = ~m_apb_req_valid;
        m_apb_req_ready = ~s_apb_req_valid;
    end

    // Cross clock domain synchronization cell
    module sync_cell (
        input wire clk,
        input wire reset,
        input wire din,
        output reg dout
    );
        reg dff1, dff2;

        always @(posedge clk or negedge reset) begin
            if (~reset) begin
                dff1 <= 1'b0;
                dff2 <= 1'b0;
                dout <= 1'b0;
            end else begin
                dff1 <= din;
                dff2 <= dff1;
                dout <= dff2;
            end
        end
    endmodule

    // Output assignments
    assign S_APB_PRDATA = s_apb_prdata_ff;
    assign S_APB_PSLVERR = s_apb_pslverr_ff;

    assign m_apb_pready_sync = M_APB_PREADY;
    assign s_apb_prdata_sync = M_APB_PRDATA;
    assign s_apb_pslverr_sync = M_APB_PSLVERR;

endmodule
