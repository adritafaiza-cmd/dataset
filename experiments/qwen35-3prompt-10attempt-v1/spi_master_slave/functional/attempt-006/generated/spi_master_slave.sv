```verilog
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

    // Internal state registers
    reg [N-1:0] shift_reg;
    reg [N-1:0] shift_reg_out;
    reg [N-1:0] shift_reg_in;
    reg shift_done;
    reg spi_busy;
    reg spi_sel_active;
    reg spi_sck_count;
    reg spi_sck_dir; // 0: falling, 1: rising (for 2x div)
    
    // State machine for SPI transaction
    localparam IDLE = 2'b00;
    localparam SELECT = 2'b01;
    localparam SHIFT = 2'b10;
    localparam DESELECT = 2'b11;

    reg [1:0] state;

    // State register
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= {N{1'b0}};
            shift_reg_out <= {N{1'b0}};
            shift_reg_in <= {N{1'b0}};
            shift_done <= 1'b0;
            spi_busy <= 1'b0;
            spi_sel_active <= 1'b0;
            spi_sck_count <= 1'b0;
            spi_sck_dir <= 1'b0;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
        end
        else begin
            state <= state;
            shift_reg <= shift_reg;
            shift_reg_out <= shift_reg_out;
            shift_reg_in <= shift_reg_in;
            shift_done <= shift_done;
            spi_busy <= spi_busy;
            spi_sel_active <= spi_sel_active;
            spi_sck_count <= spi_sck_count;
            spi_sck_dir <= spi_sck_dir;
            spi_ssel_o <= spi_ssel_o;
            spi_sck_o <= spi_sck_o;
            spi_mosi_o <= spi_mosi_o;
            di_req_o <= di_req_o;
            wr_ack_o <= wr_ack_o;
            do_valid_o <= do_valid_o;
            do_o <= do_o;
        end
    end

    // State Machine Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            state <= IDLE;
        else begin
            case (state)
                IDLE: begin
                    if (wren_i && !spi_busy) begin
                        state <= SELECT;
                        shift_reg <= di_i;
                        shift_reg_out <= {N{1'b0}};
                        shift_reg_in <= {N{1'b0}};
                        shift_done <= 1'b0;
                        spi_busy <= 1'b1;
                        di_req_o <= 1'b1;
                        wr_ack_o <= 1'b0;
                    end
                    else begin
                        di_req_o <= 1'b0;
                        wr_ack_o <= 1'b0;
                    end
                end

                SELECT: begin
                    if (spi_sck_count == SPI_2X_CLK_DIV) begin
                        state <= SHIFT;
                        spi_sel_active <= 1'b1;
                        spi_sck_count <= 1'b0;
                        spi_sck_dir <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                    end
                    else begin
                        spi_sck_count <= spi_sck_count + 1'b1;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                    end
                end

                SHIFT: begin
                    if (spi_sck_count == SPI_2X_CLK_DIV) begin
                        state <= DESELECT;
                        spi_sel_active <= 1'b0;
                        spi_sck_count <= 1'b0;
                        spi_sck_dir <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                        shift_done <= 1'b1;
                        spi_busy <= 1'b0;
                        do_valid_o <= 1'b1;
                        do_o <= shift_reg_out;
                    end
                    else begin
                        spi_sck_count <= spi_sck_count + 1'b1;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                    end
                end

                DESELECT: begin
                    if (spi_sck_count == SPI_2X_CLK_DIV) begin
                        state <= IDLE;
                        spi_sel_active <= 1'b0;
                        spi_sck_count <= 1'b0;
                        spi_sck_dir <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                        shift_done <= 1'b0;
                        do_valid_o <= 1'b0;
                        di_req_o <= 1'b0;
                        wr_ack_o <= 1'b1;
                    end
                    else begin
                        spi_sck_count <= spi_sck_count + 1'b1;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                    end
                end
            end
        end
    end

    // SPI Clock Generation (2x Divider)
    // Toggle clock on every rising edge of sclk_i to achieve 2x speed
    always @(posedge sclk_i) begin
        if (spi_busy) begin
            if (spi_sck_dir == 1'b0) begin
                spi_sck_o <= 1'b1;
                spi_sck_dir <= 1'b1;
            end
            else begin
                spi_sck_o <= 1'b0;
                spi_sck_dir <= 1'b0;
            end
        end
        else begin
            spi_sck_o <= 1'b0;
        end
    end

    // SPI MOSI Output Logic
    // Drive MOSI based on current bit position in shift_reg
    // We need to track which bit we are currently shifting out
    reg [N-1:0] bit_index;
    reg [N-1:0] bit_index_reg;

    always @(posedge sclk_i) begin
        if (spi_busy) begin
            if (spi_sck_dir == 1'b0) begin
                // Rising edge of SPI clock, shift out next bit
                bit_index_reg <= bit_index + 1'b1;
                spi_mosi_o <= shift_reg[N-1-bit_index_reg];
            end
            else begin
                // Falling edge of SPI clock
                spi_mosi_o <= 1'b0;
            end
        end
        else begin
            spi_mosi_o <= 1'b0;
        end
    end

    // SPI MISO Capture Logic
    // Capture MISO on the falling edge of SPI clock (standard SPI mode 0)
    // and shift it into the register
    always @(posedge sclk_i) begin
        if (spi_busy) begin
            if (spi_sck_dir == 1'b0) begin
                // Rising edge of SPI clock, shift in next bit
                shift_reg_in[N-1-bit_index_reg] <= spi_miso_i;
            end
            else begin
                // Falling edge of SPI clock
                // No action needed for shifting in on falling edge if we shift on rising
            end
        end
    end

    // Shift register update on completion of byte transfer
    // Actually, we need to shift the data as we go. 
    // Let's restructure the shift logic to be synchronous with the SPI clock edges.
    
    // Revised approach: Use a counter to track bit position and shift data accordingly
    reg [N-1:0] shift_reg_data;
    reg [N-1:0] shift_reg_result;
    reg [N-1:0] bit_pos;
    reg [N-1:0] bit_pos_reg;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg_data <= {N{1'b0}};
            shift_reg_result <= {N{1'b0}};
            bit_pos <= {N{1'b0}};
            bit_pos_reg <= {N{1'b0}};
        end
        else begin
            shift_reg_data <= shift_reg_data;
            shift_reg_result <= shift_reg_result;
            bit_pos <= bit_pos;
            bit_pos_reg <= bit_pos_reg;
        end
    end

    // Shift register update logic
    always @(posedge sclk_i) begin
        if (spi_busy) begin
            if (spi_sck_dir == 1'b0) begin
                // Rising edge of SPI clock
                // Shift in MISO bit at current position
                shift_reg_data[N-1-bit_pos_reg] <= spi_miso_i;
                
                // Shift out MOSI bit at current position
                spi_mosi_o <= shift_reg_data[N-1-bit_pos_reg];
                
                // Update bit position
                bit_pos_reg <= bit_pos_reg + 1'b1;
            end
            else begin
                // Falling edge of SPI clock
                spi_mosi_o <= 1'b0;
            end
        end
        else begin
            spi_mosi_o <= 1'b0;
        end
    end

    // Final result assembly
    always @(posedge sclk_i) begin
        if (spi_busy) begin
            if (spi_sck_dir == 1'b0) begin
                // Rising edge: shift in MISO
                shift_reg_result[N-1-bit_pos_reg] <= spi_miso_i;
            end
            else begin
                // Falling edge: no change
            end
        end
    end

    // Output the final result when transfer is complete
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_o <= {N{1'b0}};
            do_valid_o <= 1'b0;
        end
        else begin
            if (shift_done) begin
                do_o <= shift_reg_result;
                do_valid_o <= 1'b1;
            end
            else begin
                do_o <= do_o;
                do_valid_o <= do_valid_o;
            end
        end
    end

    // Select line control
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
        end
        else begin
            if (state == SELECT || state == SHIFT) begin
                spi_ssel_o <= 1'b0;
            end
            else begin
                spi_ssel_o <= 1'b1;
            end
        end
    end

    // Acknowledge write when transfer is complete
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 1'b0;
        end
        else begin
            if (shift_done) begin
                wr_ack_o <= 1'b1;
            end
            else begin
                wr_ack_o <= 1'b0;
            end
        end
    end

    // Request next word when transfer is complete
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b0;
        end
        else begin
            if (shift_done) begin
                di_req_o <= 1'b1;
            end
            else begin
                di_req_o <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
