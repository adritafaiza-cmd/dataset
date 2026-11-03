module apbslave #(
        parameter C_APB_ADDR_WIDTH = 12,
        parameter C_APB_DATA_WIDTH = 32,
        localparam AW = C_APB_ADDR_WIDTH,
        localparam DW = C_APB_DATA_WIDTH,
        localparam APBLSB = $clog2(C_APB_DATA_WIDTH)-3
    ) (
        input wire PCLK,
        input wire PRESETn,
        input wire PSEL,
        input wire PENABLE,
        output reg PREADY,
        input wire [AW-1:0] PADDR,
        input wire PWRITE,
        input wire [DW-1:0] PWDATA,
        input wire [DW/8-1:0] PWSTRB,
        input wire [2:0] PPROT,
        output reg [DW-1:0] PRDATA,
        output wire PSLVERR
    );

    // Internal signals
    reg [1:0] state;
    reg [1:0] next_state;
    reg [DW-1:0] reg_data;
    reg [DW-1:0] read_data;
    reg [DW-1:0] write_data;
    reg [DW/8-1:0] write_strobe;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // State transition logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (PSEL && PENABLE)
                    next_state = SETUP;
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY <= 1'b0;
            PRDATA <= {DW{1'b0}};
            PSLVERR <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY <= 1'b0;
                    PRDATA <= {DW{1'b0}};
                    PSLVERR <= 1'b0;
                end
                SETUP: begin
                    AW <= PADDR;
                    DW <= PWDATA;
                    PWRITE_L <= PWRITE;
                    PWSTRB_L <= PWSTRB;
                    PPROT_L <= PPROT;
                end
                ACCESS: begin
                    if (PWRITE_L) begin
                        // Write operation
                        write_data = DW;
                        write_strobe = PWSTRB_L;
                        for (integer i = 0; i < DW/8; i = i + 1) begin
                            if (write_strobe[i]) begin
                                reg_data[i*8 +: 8] <= write_data[i*8 +: 8];
                            end
                        end
                    end else begin
                        // Read operation
                        read_data = reg_data;
                        PRDATA <= read_data;
                    end
                    PREADY <= 1'b1;
                    PSLVERR <= 1'b0;
                end
                default: begin
                    PREADY <= 1'b0;
                    PRDATA <= {DW{1'b0}};
                    PSLVERR <= 1'b0;
                end
            endcase
        end
    end

    // Internal registers for holding SETUP phase values
    reg [AW-1:0] AW;
    reg [DW-1:0] DW;
    reg PWRITE_L;
    reg [DW/8-1:0] PWSTRB_L;
    reg [2:0] PPROT_L;

endmodule
