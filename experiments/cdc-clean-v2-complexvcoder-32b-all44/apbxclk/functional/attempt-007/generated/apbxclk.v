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
    reg s_apb_pready_reg;
    reg m_apb_psel_reg;
    reg m_apb_penable_reg;
    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;
    reg [DW-1:0] s_apb_prdata_reg;
    reg s_apb_pslverr_reg;
    reg transfer_in_progress;

    // Source APB domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_prdata_reg <= 0;
            s_apb_pslverr_reg <= 1'b0;
        end else begin
            if (!transfer_in_progress && S_APB_PSEL && S_APB_PENABLE) begin
                m_apb_psel_reg <= 1'b1;
                m_apb_paddr_reg <= S_APB_PADDR;
                m_apb_pwrite_reg <= S_APB_PWRITE;
                m_apb_pwdata_reg <= S_APB_PWDATA;
                m_apb_pwstrb_reg <= S_APB_PWSTRB;
                m_apb_pprot_reg <= S_APB_PPROT;
                transfer_in_progress <= 1'b1;
            end

            if (M_APB_PREADY) begin
                s_apb_prdata_reg <= M_APB_PRDATA;
                s_apb_pslverr_reg <= M_APB_PSLVERR;
                s_apb_pready_reg <= 1'b1;
                m_apb_psel_reg <= 1'b0;
                transfer_in_progress <= 1'b0;
            end else begin
                s_apb_pready_reg <= 1'b0;
            end

            S_APB_PREADY <= s_apb_pready_reg;
        end
    end

    // Destination APB domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            if (m_apb_psel_reg) begin
                M_APB_PSEL <= 1'b1;
                M_APB_PADDR <= m_apb_paddr_reg;
                M_APB_PWRITE <= m_apb_pwrite_reg;
                M_APB_PWDATA <= m_apb_pwdata_reg;
                M_APB_PWSTRB <= m_apb_pwstrb_reg;
                M_APB_PPROT <= m_apb_pprot_reg;
                M_APB_PENABLE <= 1'b1;
            end else begin
                M_APB_PENABLE <= 1'b0;
            end
        end
    end

    // Registered crossing if OPT_REGISTERED is set
    generate
        if (OPT_REGISTERED == 1'b1) begin : registered_crossing
            reg [DW-1:0] s_apb_prdata_reg_cross;
            reg s_apb_pslverr_reg_cross;

            always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
                if (!S_PRESETn) begin
                    s_apb_prdata_reg_cross <= 0;
                    s_apb_pslverr_reg_cross <= 1'b0;
                end else begin
                    s_apb_prdata_reg_cross <= s_apb_prdata_reg;
                    s_apb_pslverr_reg_cross <= s_apb_pslverr_reg;
                end
            end

            always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
                if (!S_PRESETn) begin
                    S_APB_PRDATA <= 0;
                    S_APB_PSLVERR <= 1'b0;
                end else begin
                    S_APB_PRDATA <= s_apb_prdata_reg_cross;
                    S_APB_PSLVERR <= s_apb_pslverr_reg_cross;
                end
            end
        end else begin : combinational_crossing
            assign S_APB_PRDATA = s_apb_prdata_reg;
            assign S_APB_PSLVERR = s_apb_pslverr_reg;
        end
    endgenerate

endmodule
