module apbslave #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH,
        localparam  APBLSB = $clog2(C_APB_DATA_WIDTH/8)
    ) (
        input   wire            PCLK, 
        input   wire            PRESETn,
        input   wire            PSEL,
        input   wire            PENABLE,
        output  reg             PREADY,
        input   wire [AW-1:0]   PADDR,
        input   wire            PWRITE,
        input   wire [DW-1:0]   PWDATA,
        input   wire [APBLSB:0] PWSTRB,
        input   wire [2:0]      PPROT,
        output  reg  [DW-1:0]   PRDATA,
        output  wire            PSLVERR
    );

    // Internal signals
    reg [AW-1:0]  address;
    reg [DW-1:0]  data_in;
    reg [DW-1:0]  data_out;
    reg [APBLSB:0] write_strobe;
    reg           write_enable;
    reg           read_enable;
    reg           ready;
    reg           slverr;
    reg [1:0]     state;
    reg [1:0]     next_state;

    // State definitions
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    // Memory model
    reg [DW-1:0] memory [0:(1<<AW)-1];

    // State machine
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
                if (PSEL && !PENABLE) begin
                    next_state = SETUP;
                end
            end
            SETUP: begin
                if (PSEL && PENABLE) begin
                    next_state = ACCESS;
                end else if (!PSEL) begin
                    next_state = IDLE;
                end
            end
            ACCESS: begin
                if (!PSEL) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Output logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY  <= 1'b0;
            PRDATA  <= {DW{1'b0}};
            PSLVERR <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    PREADY  <= 1'b0;
                    PRDATA  <= {DW{1'b0}};
                    PSLVERR <= 1'b0;
                end
                SETUP: begin
                    PREADY  <= 1'b1;
                    PSLVERR <= 1'b0;
                end
                ACCESS: begin
                    if (PWRITE) begin
                        for (integer i = 0; i < (DW/8); i = i + 1) begin
                            if (PWSTRB[i]) begin
                                memory[address][(i+1)*8-1 -: 8] <= PWDATA[(i+1)*8-1 -: 8];
                            end
                        end
                    end else begin
                        PRDATA <= memory[address];
                    end
                    PREADY  <= 1'b1;
                    PSLVERR <= (address >= (1<<AW)) ? 1'b1 : 1'b0;
                end
            endcase
        end
    end

endmodule
