module apbslave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam APBLSB = $clog2(C_APB_DATA_WIDTH)-3
) (
    input wire PCLK, PRESETn,
    input wire PSEL,
    input wire PENABLE,
    output reg PREADY,
    input wire [AW-1:0] PADDR,
    input wire PWRITE,
    input wire [DW-1:0] PWDATA,
    input wire [DW/8-1:0] PWSTRB,
    input wire [2:0] PPROT,
    output reg [DW-1:0] PRDATA,
    output reg PSLVERR
);

    // Internal signals
    reg [1:0] state;
    reg write_enable;
    reg read_enable;
    reg address_valid;
    reg data_valid;
    reg ready_to_send;

    // State definitions
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;

    // State machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PREADY <= 1'b0;
            PRDATA <= 32'b0;
            PSLVERR <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY <= 1'b0;
                    PRDATA <= 32'b0;
                    PSLVERR <= 1'b0;
                    if (PSEL && PENABLE) begin
                        state <= ADDR;
                    end
                end
                ADDR: begin
                    PREADY <= 1'b0;
                    PRDATA <= 32'b0;
                    PSLVERR <= 1'b0;
                    if (PWRITE) begin
                        state <= DATA;
                    end
                end
                DATA: begin
                    PREADY <= 1'b1;
                    PRDATA <= 32'b0;
                    PSLVERR <= 1'b0;
                    if (PREADY) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Control signals
    assign write_enable = PWRITE && PSEL && PENABLE;
    assign read_enable = !PWRITE && PSEL && PENABLE;
    assign address_valid = PSEL && PENABLE;
    assign data_valid = PSEL && PENABLE && (PWRITE || !PWRITE);
    assign ready_to_send = PSEL && PENABLE && PREADY;

    // Data handling
    reg [DW-1:0] memory [0:2**AW-1];
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            memory <= '{default: 32'b0};
        end else begin
            if (write_enable) begin
                for (int i = 0; i < DW/8; i++) begin
                    if (PWSTRB[i]) begin
                        memory[PADDR][i*8 +: 8] <= PWDATA[i*8 +: 8];
                    end
                end
            end
            if (read_enable) begin
                PRDATA <= memory[PADDR];
            end
        end
    end

endmodule
