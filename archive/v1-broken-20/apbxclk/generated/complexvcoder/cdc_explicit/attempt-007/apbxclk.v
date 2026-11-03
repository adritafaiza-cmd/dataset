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

    reg [AW-1:0] s_addr;
    reg s_write;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0] s_prot;
    wire [AW-1:0] m_addr;
    wire m_write;
    wire [DW-1:0] m_wdata;
    wire [DW/8-1:0] m_wstrb;
    wire [2:0] m_prot;
    wire [DW-1:0] m_rdata;
    wire m_slverr;
    reg s_ready;
    reg m_ready;

    // S_APB to internal signals
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr <= 0;
            s_write <= 0;
            s_wdata <= 0;
            s_wstrb <= 0;
            s_prot <= 0;
            s_ready <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE) begin
                s_addr <= S_APB_PADDR;
                s_write <= S_APB_PWRITE;
                s_wdata <= S_APB_PWDATA;
                s_wstrb <= S_APB_PWSTRB;
                s_prot <= S_APB_PPROT;
                s_ready <= 1;
            end else begin
                s_ready <= 0;
            end
        end
    end

    // Internal signals to M_APB
    assign m_addr = s_addr;
    assign m_write = s_write;
    assign m_wdata = s_wdata;
    assign m_wstrb = s_wstrb;
    assign m_prot = s_prot;

    // M_APB to internal signals
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_ready <= 0;
            m_rdata <= 0;
            m_slverr <= 0;
        end else begin
            m_ready <= M_APB_PREADY;
            m_rdata <= M_APB_PRDATA;
            m_slverr <= M_APB_PSLVERR;
        end
    end

    // S_APB to M_APB and back to S_APB
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
        end else begin
            if (s_ready && m_ready) begin
                S_APB_PREADY <= 1;
                S_APB_PRDATA <= m_rdata;
                S_APB_PSLVERR <= m_slverr;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    // Destination reset output
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1;
        end else begin
            M_PRESETn <= 0;
        end
    end

    // M_APB_PSEL and M_APB_PENABLE
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
        end else begin
            if (s_ready && m_ready) begin
                M_APB_PSEL <= 1;
                M_APB_PENABLE <= 1;
            end else begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
            end
        end
    end

    // M_APB_PADDR, M_APB_PWRITE, M_APB_PWDATA, M_APB_PWSTRB, M_APB_PPROT
    assign M_APB_PADDR = m_addr;
    assign M_APB_PWRITE = m_write;
    assign M_APB_PWDATA = m_wdata;
    assign M_APB_PWSTRB = m_wstrb;
    assign M_APB_PPROT = m_prot;

endmodule
