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

    reg [AW-1:0] s_addr_reg, m_addr_reg;
    reg [DW-1:0] s_wdata_reg, m_wdata_reg;
    reg [DW/8-1:0] s_wstrb_reg, m_wstrb_reg;
    reg [2:0] s_prot_reg, m_prot_reg;
    reg s_pwrite_reg, m_pwrite_reg;
    reg s_psel_reg, m_psel_reg;
    reg s_penable_reg, m_penable_reg;
    reg s_pready_reg, m_pready_reg;
    reg s_prdata_reg [DW-1:0];
    reg s_pslverr_reg;

    // S_APB to M_APB cross-domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_addr_reg <= {AW{1'b0}};
            m_wdata_reg <= {DW{1'b0}};
            m_wstrb_reg <= {DW/8{1'b0}};
            m_prot_reg <= 3'b000;
            m_pwrite_reg <= 1'b0;
            m_psel_reg <= 1'b0;
            m_penable_reg <= 1'b0;
            M_PRESETn <= 1'b1;
        end else begin
            m_addr_reg <= S_APB_PADDR;
            m_wdata_reg <= S_APB_PWDATA;
            m_wstrb_reg <= S_APB_PWSTRB;
            m_prot_reg <= S_APB_PPROT;
            m_pwrite_reg <= S_APB_PWRITE;
            m_psel_reg <= S_APB_PSEL;
            m_penable_reg <= S_APB_PENABLE;
            M_PRESETn <= 1'b0;
        end
    end

    // M_APB to S_APB cross-domain logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            s_pready_reg <= 1'b0;
            s_prdata_reg <= {DW{1'b0}};
            s_pslverr_reg <= 1'b0;
        end else begin
            s_pready_reg <= M_APB_PREADY;
            s_prdata_reg <= M_APB_PRDATA;
            s_pslverr_reg <= M_APB_PSLVERR;
        end
    end

    // Output logic
    assign S_APB_PREADY = s_pready_reg;
    assign S_APB_PRDATA = s_prdata_reg;
    assign S_APB_PSLVERR = s_pslverr_reg;

endmodule
