module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    // Internal signals
    logic [ASIZE-1:0] wp;
    logic [ASIZE-1:0] rp;
    logic [DSIZE-1:0] fifo [0:(1<<ASIZE)-1];
    logic [ASIZE-1:0] wp_next;
    logic [ASIZE-1:0] rp_next;
    logic wfull_reg;
    logic wfull_next;
    logic awfull_reg;
    logic awfull_next;
    logic rempty_reg;
    logic rempty_next;
    logic arempty_reg;
    logic arempty_next;
    logic [DSIZE-1:0] rdata_next;
    logic write_request;
    logic read_request;

    // Write logic
    assign write_request = winc & ~wfull_reg;
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wp <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else begin
            wp_next = wp;
            wfull_next = (wp_next == rp_next);
            awfull_next = (wp_next == rp_next - 1);
            if (write_request) begin
                wp_next = wp_next + 1;
            end
            wfull_reg <= wfull_next;
            awfull_reg <= awfull_next;
        end
    end

    // Read logic
    assign read_request = rinc & ~rempty_reg;
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rp <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
            rdata_next = 0;
        end else begin
            rp_next = rp;
            rempty_next = (rp_next == wp_next);
            arempty_next = (rp_next == wp_next - 1);
            if (read_request) begin
                rp_next = rp_next + 1;
                rdata_next = fifo[rp];
            end else begin
                rdata_next = fifo[rp];
            end
            rempty_reg <= rempty_next;
            arempty_reg <= arempty_next;
        end
    end

    // FIFO memory
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = fifo[rp];
        end else begin
            assign rdata = rdata_next;
        end
    endgenerate

    // Outputs
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
