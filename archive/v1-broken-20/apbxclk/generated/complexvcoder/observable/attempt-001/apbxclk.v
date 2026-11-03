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

    reg [AW-1:0] slave_addr;
    reg slave_write;
    reg [DW-1:0] slave_wdata;
    reg [DW/8-1:0] slave_wstrb;
    reg [2:0] slave_prot;
    wire [DW-1:0] slave_rdata;
    wire slave_rvalid;
    wire slave_rready;
    wire slave_err;

    reg [AW-1:0] master_addr;
    reg master_write;
    reg [DW-1:0] master_wdata;
    reg [DW/8-1:0] master_wstrb;
    reg [2:0] master_prot;
    wire [DW-1:0] master_rdata;
    wire master_rvalid;
    wire master_rready;
    wire master_err;

    reg [AW-1:0] addr_reg;
    reg write_reg;
    reg [DW-1:0] wdata_reg;
    reg [DW/8-1:0] wstrb_reg;
    reg [2:0] prot_reg;
    wire [DW-1:0] rdata_reg;
    wire rvalid_reg;
    wire rready_reg;
    wire err_reg;

    reg [AW-1:0] master_addr_reg;
    reg master_write_reg;
    reg [DW-1:0] master_wdata_reg;
    reg [DW/8-1:0] master_wstrb_reg;
    reg [2:0] master_prot_reg;
    wire [DW-1:0] master_rdata_reg;
    wire master_rvalid_reg;
    wire master_rready_reg;
    wire master_err_reg;

    reg master_psel_reg;
    reg master_penable_reg;
    reg master_pready_reg;
    reg master_paddr_reg;
    reg master_pwrite_reg;
    reg [DW-1:0] master_pwdata_reg;
    reg [DW/8-1:0] master_pstrb_reg;
    reg [2:0] master_pprot_reg;
    wire master_prdata_reg;
    wire master_pslverr_reg;

    reg [AW-1:0] slave_addr_reg;
    reg slave_write_reg;
    reg [DW-1:0] slave_wdata_reg;
    reg [DW/8-1:0] slave_wstrb_reg;
    reg [2:0] slave_prot_reg;
    wire [DW-1:0] slave_rdata_reg;
    wire slave_rvalid_reg;
    wire slave_rready_reg;
    wire slave_err_reg;

    wire slave_psel_reg;
    wire slave_penable_reg;
    wire slave_pready_reg;
    wire [AW-1:0] slave_paddr_reg;
    wire slave_pwrite_reg;
    wire [DW-1:0] slave_pwdata_reg;
    wire [DW/8-1:0] slave_pstrb_reg;
    wire [2:0] slave_pprot_reg;
    reg [DW-1:0] slave_prdata_reg;
    reg slave_pslverr_reg;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            slave_addr_reg <= 0;
            slave_write_reg <= 0;
            slave_wdata_reg <= 0;
            slave_wstrb_reg <= 0;
            slave_prot_reg <= 0;
            slave_psel_reg <= 0;
            slave_penable_reg <= 0;
            slave_pready_reg <= 0;
            slave_prdata_reg <= 0;
            slave_pslverr_reg <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE) begin
                slave_addr_reg <= S_APB_PADDR;
                slave_write_reg <= S_APB_PWRITE;
                slave_wdata_reg <= S_APB_PWDATA;
                slave_wstrb_reg <= S_APB_PWSTRB;
                slave_prot_reg <= S_APB_PPROT;
                slave_psel_reg <= S_APB_PSEL;
                slave_penable_reg <= S_APB_PENABLE;
                slave_pready_reg <= 1;
            end else begin
                slave_pready_reg <= 0;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            master_addr_reg <= 0;
            master_write_reg <= 0;
            master_wdata_reg <= 0;
            master_wstrb_reg <= 0;
            master_prot_reg <= 0;
            master_psel_reg <= 0;
            master_penable_reg <= 0;
            master_pready_reg <= 0;
            master_prdata_reg <= 0;
            master_pslverr_reg <= 0;
        end else begin
            if (master_psel_reg && master_penable_reg) begin
                master_addr_reg <= master_addr;
                master_write_reg <= master_write;
                master_wdata_reg <= master_wdata;
                master_wstrb_reg <= master_wstrb;
                master_prot_reg <= master_prot;
                master_psel_reg <= master_psel_reg;
                master_penable_reg <= master_penable_reg;
                master_pready_reg <= 1;
            end else begin
                master_pready_reg <= 0;
            end
        end
    end

    assign S_APB_PREADY = slave_pready_reg;
    assign S_APB_PRDATA = slave_prdata_reg;
    assign S_APB_PSLVERR = slave_pslverr_reg;

    assign M_PRESETn = master_presetn_reg;
    assign M_APB_PSEL = master_psel_reg;
    assign M_APB_PENABLE = master_penable_reg;
    assign M_APB_PADDR = master_addr_reg;
    assign M_APB_PWRITE = master_write_reg;
    assign M_APB_PWDATA = master_wdata_reg;
    assign M_APB_PWSTRB = master_wstrb_reg;
    assign M_APB_PPROT = master_prot_reg;
    assign M_APB_PRDATA = master_prdata_reg;
    assign M_APB_PSLVERR = master_pslverr_reg;

endmodule
