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
reg [AW-1:0] s_apb_paddr_sync;
reg [DW-1:0] s_apb_pwdata_sync;
reg [DW/8-1:0] s_apb_pwstrb_sync;
reg [2:0] s_apb_pprot_sync;
reg s_apb_psel_sync;
reg s_apb_pwrite_sync;
reg [DW-1:0] m_apb_prdata_sync;
reg m_apb_pslverr_sync;
reg m_apb_pready_sync;
reg transaction_active;
reg transaction_complete;
reg m_apb_psel_reg;
reg m_apb_penable_reg;

// Synchronizers for control signals from S_APB to M_APB
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
        s_apb_psel_sync <= 1'b0;
        s_apb_pwrite_sync <= 1'b0;
    end else begin
        s_apb_psel_sync <= S_APB_PSEL;
        s_apb_pwrite_sync <= S_APB_PWRITE;
    end
end

// Synchronizers for payload signals from S_APB to M_APB
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
        s_apb_paddr_sync <= {AW{1'b0}};
        s_apb_pwdata_sync <= {DW{1'b0}};
        s_apb_pwstrb_sync <= {DW/8{1'b0}};
        s_apb_pprot_sync <= 3'b000;
    end else begin
        s_apb_paddr_sync <= S_APB_PADDR;
        s_apb_pwdata_sync <= S_APB_PWDATA;
        s_apb_pwstrb_sync <= S_APB_PWSTRB;
        s_apb_pprot_sync <= S_APB_PPROT;
    end
end

// Synchronizers for control signals from M_APB to S_APB
always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
        m_apb_pready_sync <= 1'b0;
        m_apb_prdata_sync <= {DW{1'b0}};
        m_apb_pslverr_sync <= 1'b0;
    end else begin
        m_apb_pready_sync <= M_APB_PREADY;
        m_apb_prdata_sync <= M_APB_PRDATA;
        m_apb_pslverr_sync <= M_APB_PSLVERR;
    end
end

// M_PRESETn generation
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
        M_PRESETn <= 1'b0;
    end else begin
        M_PRESETn <= 1'b1;
    end
end

// M_APB control signals generation
always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
        M_APB_PSEL <= 1'b0;
        M_APB_PENABLE <= 1'b0;
        m_apb_psel_reg <= 1'b0;
        m_apb_penable_reg <= 1'b0;
        transaction_active <= 1'b0;
        transaction_complete <= 1'b0;
    end else begin
        if (!transaction_active && s_apb_psel_sync) begin
            m_apb_psel_reg <= 1'b1;
            transaction_active <= 1'b1;
        end else if (transaction_active && M_APB_PREADY) begin
            m_apb_penable_reg <= 1'b1;
        end else if (transaction_active && m_apb_penable_reg && M_APB_PREADY) begin
            transaction_complete <= 1'b1;
        end else if (transaction_complete) begin
            m_apb_psel_reg <= 1'b0;
            m_apb_penable_reg <= 1'b0;
            transaction_active <= 1'b0;
            transaction_complete <= 1'b0;
        end
        M_APB_PSEL <= m_apb_psel_reg;
        M_APB_PENABLE <= m_apb_penable_reg;
    end
end

// M_APB payload signals generation
assign M_APB_PADDR = s_apb_paddr_sync;
assign M_APB_PWRITE = s_apb_pwrite_sync;
assign M_APB_PWDATA = s_apb_pwdata_sync;
assign M_APB_PWSTRB = s_apb_pwstrb_sync;
assign M_APB_PPROT = s_apb_pprot_sync;

// S_APB response signals generation
assign S_APB_PREADY = transaction_complete;
assign S_APB_PRDATA = m_apb_prdata_sync;
assign S_APB_PSLVERR = m_apb_pslverr_sync;

endmodule
