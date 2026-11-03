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
    reg [DW-1:0] s_apb_prdata_reg;
    reg s_apb_pslverr_reg;
    reg m_apb_psel_reg;
    reg m_apb_penable_reg;
    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;
    reg request_valid;
    reg response_valid;

    // S_APB domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_prdata_reg <= {DW{1'b0}};
            s_apb_pslverr_reg <= 1'b0;
            request_valid <= 1'b0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !request_valid) begin
                m_apb_psel_reg <= 1'b1;
                m_apb_paddr_reg <= S_APB_PADDR;
                m_apb_pwrite_reg <= S_APB_PWRITE;
                m_apb_pwdata_reg <= S_APB_PWDATA;
                m_apb_pwstrb_reg <= S_APB_PWSTRB;
                m_apb_pprot_reg <= S_APB_PPROT;
                request_valid <= 1'b1;
            end

            if (response_valid) begin
                S_APB_PREADY <= 1'b1;
                s_apb_prdata_reg <= M_APB_PRDATA;
                s_apb_pslverr_reg <= M_APB_PSLVERR;
                request_valid <= 1'b0;
                response_valid <= 1'b0;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    // M_APB domain logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            if (request_valid && !M_APB_PSEL) begin
                M_APB_PSEL <= 1'b1;
                M_APB_PENABLE <= 1'b0;
            end else if (M_APB_PSEL && !M_APB_PENABLE) begin
                M_APB_PENABLE <= 1'b1;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
                response_valid <= 1'b1;
            end
        end
    end

    // Registered crossing if OPT_REGISTERED is set
    generate
        if (OPT_REGISTERED) begin
            reg [DW-1:0] m_apb_prdata_reg;
            reg m_apb_pslverr_reg;
            reg m_apb_pready_reg;

            // Cross register from M_APB to S_APB
            always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
                if (!S_PRESETn) begin
                    m_apb_prdata_reg <= {DW{1'b0}};
                    m_apb_pslverr_reg <= 1'b0;
                    m_apb_pready_reg <= 1'b0;
                end else begin
                    m_apb_prdata_reg <= M_APB_PRDATA;
                    m_apb_pslverr_reg <= M_APB_PSLVERR;
                    m_apb_pready_reg <= M_APB_PREADY;
                end
            end

            assign S_APB_PRDATA = m_apb_prdata_reg;
            assign S_APB_PSLVERR = m_apb_pslverr_reg;
            assign response_valid = m_apb_pready_reg;
        end else begin
            assign S_APB_PRDATA = M_APB_PRDATA;
            assign S_APB_PSLVERR = M_APB_PSLVERR;
            assign response_valid = M_APB_PREADY;
        end
    endgenerate

    // Output assignments
    assign M_APB_PADDR = m_apb_paddr_reg;
    assign M_APB_PWRITE = m_apb_pwrite_reg;
    assign M_APB_PWDATA = m_apb_pwdata_reg;
    assign M_APB_PWSTRB = m_apb_pwstrb_reg;
    assign M_APB_PPROT = m_apb_pprot_reg;

endmodule
