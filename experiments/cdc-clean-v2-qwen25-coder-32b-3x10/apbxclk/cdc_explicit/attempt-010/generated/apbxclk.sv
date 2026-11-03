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

    // Source side registers
    reg [AW-1:0] s_addr_reg;
    reg s_write_reg;
    reg [DW-1:0] s_wdata_reg;
    reg [DW/8-1:0] s_wstrb_reg;
    reg [2:0] s_prot_reg;
    reg s_req_valid;

    // Destination side registers
    reg [AW-1:0] m_addr_reg;
    reg m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg [2:0] m_prot_reg;
    reg m_req_valid;

    // Cross-domain synchronization
    reg [1:0] s_req_sync;
    reg [1:0] m_req_sync;

    // Source side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_req_valid <= 1'b0;
            s_addr_reg <= {AW{1'b0}};
            s_write_reg <= 1'b0;
            s_wdata_reg <= {DW{1'b0}};
            s_wstrb_reg <= {DW/8{1'b0}};
            s_prot_reg <= 3'b000;
            s_req_sync <= 2'b00;
            S_APB_PREADY <= 1'b0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !s_req_valid) begin
                s_req_valid <= 1'b1;
                s_addr_reg <= S_APB_PADDR;
                s_write_reg <= S_APB_PWRITE;
                s_wdata_reg <= S_APB_PWDATA;
                s_wstrb_reg <= S_APB_PWSTRB;
                s_prot_reg <= S_APB_PPROT;
            end else if (m_req_sync[1]) begin
                s_req_valid <= 1'b0;
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end

            // Synchronize request to destination clock domain
            s_req_sync <= {s_req_sync[0], s_req_valid};
        end
    end

    // Destination side logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            m_req_valid <= 1'b0;
            m_addr_reg <= {AW{1'b0}};
            m_write_reg <= 1'b0;
            m_wdata_reg <= {DW{1'b0}};
            m_wstrb_reg <= {DW/8{1'b0}};
            m_prot_reg <= 3'b000;
            m_req_sync <= 2'b00;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            // Synchronize request from source clock domain
            m_req_sync <= {m_req_sync[0], s_req_sync[1]};

            if (m_req_sync[1] && !m_req_valid) begin
                m_req_valid <= 1'b1;
                m_addr_reg <= s_addr_reg;
                m_write_reg <= s_write_reg;
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
                m_prot_reg <= s_prot_reg;
            end

            if (M_APB_PREADY) begin
                m_req_valid <= 1'b0;
            end

            // APB protocol handling
            if (m_req_valid) begin
                M_APB_PSEL <= 1'b1;
                M_APB_PENABLE <= 1'b1;
            end else begin
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
            end
        end
    end

    // Output assignments
    assign S_APB_PRDATA = M_APB_PRDATA;
    assign S_APB_PSLVERR = M_APB_PSLVERR;

    assign M_APB_PADDR = m_addr_reg;
    assign M_APB_PWRITE = m_write_reg;
    assign M_APB_PWDATA = m_wdata_reg;
    assign M_APB_PWSTRB = m_wstrb_reg;
    assign M_APB_PPROT = m_prot_reg;

endmodule
