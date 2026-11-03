module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    reg [N-1:0]       shift_reg;
    reg [3:0]         bit_cnt;
    reg               spi_sck;
    reg               spi_ssel;
    reg [N-1:0]       di_sync;
    reg               wren_sync;
    reg [1:0]         state;
    reg [1:0]         next_state;
    reg [1:0]         state_ff;
    reg [1:0]         next_state_ff;
    reg [1:0]         state_sync;
    reg [1:0]         next_state_sync;

    // State definitions
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE = 2'b10;

    // Clock domain crossing for wren_i and di_i
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 1'b0;
            di_sync <= {N{1'b0}};
        end else begin
            wren_sync <= wren_i;
            di_sync <= di_i;
        end
    end

    // State machine in pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            state_ff <= IDLE;
            state_sync <= IDLE;
        end else begin
            state <= next_state;
            state_ff <= state;
            state_sync <= state_ff;
        end
    end

    // Next state logic in pclk domain
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (wren_sync) begin
                    next_state = TRANSFER;
                end
            end
            TRANSFER: begin
                if (bit_cnt == N-1) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // Shift register and bit counter
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= {N{1'b0}};
            bit_cnt <= 4'b0;
            spi_sck <= 1'b0;
            spi_ssel <= 1'b1;
        end else begin
            case (state_sync)
                IDLE: begin
                    if (wren_sync) begin
                        shift_reg <= di_sync;
                        bit_cnt <= 4'b0;
                        spi_ssel <= 1'b0;
                    end
                end
                TRANSFER: begin
                    spi_sck <= ~spi_sck;
                    if (spi_sck) begin
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                DONE: begin
                    spi_ssel <= 1'b1;
                end
            endcase
        end
    end

    // Outputs
    assign spi_sck_o = spi_sck;
    assign spi_ssel_o = spi_ssel;
    assign spi_mosi_o = shift_reg[N-1];

    // Handshake signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
        end else begin
            di_req_o <= (state == IDLE);
            wr_ack_o <= (state == TRANSFER) & (state_ff == IDLE);
            do_valid_o <= (state == DONE) & (state_ff == TRANSFER);
            if (state == DONE) begin
                do_o <= shift_reg;
            end
        end
    end

endmodule
