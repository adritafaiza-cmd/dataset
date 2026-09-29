module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    input wire S_APB_PCLK,
    input wire S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [(DW/8)-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output wire [AW-1:0] M_APB_PADDR,
    output reg M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [(DW/8)-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    // S_APB domain signals
    reg s_req;
    reg [AW-1:0] s_addr;
    reg [DW-1:0] s_wdata;
    reg s_write;
    reg [(DW/8)-1:0] s_strb;
    reg [2:0] s_prot;

    // Synchronization registers for M_APB domain
    reg s_req_meta, s_req_sync;

    // M_APB domain signals
    reg m_ack;
    reg [AW-1:0] m_addr;
    reg [DW-1:0] m_wdata;
    reg m_write;
    reg [(DW/8)-1:0] m_strb;
    reg [2:0] m_prot;

    // Response registers
    reg [DW-1:0] m_prdata;
    reg m_pslverr;

    // Synchronization registers for ack from M_APB to S_APB
    reg m_ack_meta, m_ack_sync;

    // S_APB domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_req <= 0;
            s_addr <= 0;
            s_wdata <= 0;
            s_write <= 0;
            s_strb <= 0;
            s_prot <= 0;
            s_req_meta <= 0;
            s_req_sync <= 0;
            m_ack_meta <= 0;
            m_ack_sync <= 0;
        end else begin
            // Capture transaction parameters on access phase
            if (S_APB_PSEL && S_APB_PENABLE) begin
                s_addr <= S_APB_PADDR;
                s_wdata <= S_APB_PWDATA;
                s_write <= S_APB_PWRITE;
                s_strb <= S_APB_PWSTRB;
                s_prot <= S_APB_PPROT;
                s_req <= 1;
            end else begin
                s_req <= 0;
            end

            // Synchronize request to M_APB domain
            s_req_meta <= s_req;
            s_req_sync <= s_req_meta;

            // Synchronize ack from M_APB domain
            m_ack_meta <= m_ack;
            m_ack_sync <= m_ack_meta;
        end
    end

    // Assign S_APB outputs
    assign S_APB_PREADY = m_ack_sync;
    assign S_APB_PRDATA = m_prdata;
    assign S_APB_PSLVERR = m_pslverr;

    // M_APB domain logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            M_APB_PADDR <= 0;
            M_APB_PWDATA <= 0;
            M_APB_PWRITE <= 0;
            M_APB_PWSTRB <= 0;
            M_APB_PPROT <= 0;
            m_ack <= 0;
            m_prdata <= 0;
            m_pslverr <= 0;
            m_addr <= 0;
            m_wdata <= 0;
            m_write <= 0;
            m_strb <= 0;
            m_prot <= 0;
        end else begin
            // Handle request from S_APB domain
            if (s_req_sync && !M_APB_PSEL) begin
                M_APB_PSEL <= 1;
                M_APB_PENABLE <= 0;
                M_APB_PADDR <= s_addr;
                M_APB_PWDATA <= s_wdata;
                M_APB_PWRITE <= s_write;
                M_APB_PWSTRB <= s_strb;
                M_APB_PPROT <= s_prot;
                m_addr <= s_addr;
                m_wdata <= s_wdata;
                m_write <= s_write;
                m_strb <= s_strb;
                m_prot <= s_prot;
            end

            // Transition to PENABLE phase
            if (M_APB_PSEL && !M_APB_PENABLE) begin
                M_APB_PENABLE <= 1;
            end

            // Wait for PREADY
            if (M_APB_PSEL && M_APB_PENABLE) begin
                if (M_APB_PREADY) begin
                    m_prdata <= M_APB_PRDATA;
                    m_pslverr <= M_APB_PSLVERR;
                    M_APB_PSEL <= 0;
                    M_APB_PENABLE <= 0;
                    m_ack <= 1;
                end else begin
                    M_APB_PENABLE <= 1;
                end
            end

            // Deassert ack
            if (m_ack) begin
                m_ack <= 0;
            end
        end
    end

endmodule
