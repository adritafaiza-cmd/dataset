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
    output wire M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [(DW/8)-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    // Source domain registers
    reg [AW-1:0] s_addr;
    reg s_write;
    reg [DW-1:0] s_wdata;
    reg [(DW/8)-1:0] s_wstrb;
    reg [2:0] s_pprot;
    reg s_transfer_req;

    // CDC synchronization registers
    reg m_transfer_req_sync1, m_transfer_req_sync2;
    reg s_ack_sync1, s_ack_sync2;

    // Destination domain registers
    reg [AW-1:0] m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [(DW/8)-1:0] m_wstrb;
    reg [2:0] m_pprot;
    reg m_transfer_ack;

    // APB state machine states
    localparam M_IDLE = 0, M_SETUP = 1, M_ACCESS = 2;
    reg [1:0] m_state;

    // Source domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_transfer_req <= 0;
            s_addr <= 0;
            s_write <= 0;
            s_wdata <= 0;
            s_wstrb <= 0;
            s_pprot <= 0;
        end else begin
            if (S_APB_PSEL && !S_APB_PENABLE) begin
                s_addr <= S_APB_PADDR;
                s_write <= S_APB_PWRITE;
                s_wdata <= S_APB_PWDATA;
                s_wstrb <= S_APB_PWSTRB;
                s_pprot <= S_APB_PPROT;
                s_transfer_req <= 1;
            end else if (s_ack_sync2) begin
                s_transfer_req <= 0;
            end
        end
    end

    // CDC for transfer request to destination domain
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_transfer_req_sync1 <= 0;
            m_transfer_req_sync2 <= 0;
        end else begin
            m_transfer_req_sync1 <= s_transfer_req;
            m_transfer_req_sync2 <= m_transfer_req_sync1;
        end
    end

    // Destination domain APB state machine
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_state <= M_IDLE;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_transfer_ack <= 0;
            m_addr <= 0;
            m_write <= 0;
            m_wdata <= 0;
            m_wstrb <= 0;
            m_pprot <= 0;
            M_PRESETn <= 0;
        end else begin
            M_PRESETn <= 1;
            m_transfer_ack <= 0;

            case (m_state)
                M_IDLE: begin
                    if (m_transfer_req_sync2) begin
                        m_addr <= s_addr;
                        m_write <= s_write;
                        m_wdata <= s_wdata;
                        m_wstrb <= s_wstrb;
                        m_pprot <= s_pprot;
                        M_APB_PSEL <= 1;
                        M_APB_PENABLE <= 0;
                        m_state <= M_SETUP;
                    end
                end
                M_SETUP: begin
                    M_APB_PENABLE <= 1;
                    m_state <= M_ACCESS;
                end
                M_ACCESS: begin
                    if (M_APB_PREADY) begin
                        M_APB_PSEL <= 0;
                        M_APB_PENABLE <= 0;
                        m_transfer_ack <= 1;
                        m_state <= M_IDLE;
                    end
                end
            endcase
        end
    end

    // CDC for transfer acknowledgment to source domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_ack_sync1 <= 0;
            s_ack_sync2 <= 0;
        end else begin
            s_ack_sync1 <= m_transfer_ack;
            s_ack_sync2 <= s_ack_sync1;
        end
    end

    // Assign source ready and outputs
    assign S_APB_PREADY = s_ack_sync2;
    assign S_APB_PRDATA = M_APB_PRDATA;
    assign S_APB_PSLVERR = M_APB_PSLVERR;

    // Destination domain outputs
    assign M_APB_PADDR = m_addr;
    assign M_APB_PWRITE = m_write;
    assign M_APB_PWDATA = m_wdata;
    assign M_APB_PWSTRB = m_wstrb;
    assign M_APB_PPROT = m_pprot;

endmodule
