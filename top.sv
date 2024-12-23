module top ();

    // AXI4-Lite read and write response types
    typedef enum logic [1:0] {
        RESP_OKAY       = 2'b00,    // Transaction completed successfully
        RESP_EXOKAY     = 2'b01,    // Exclusvie access successful
        RESP_SLVERR     = 2'b10,    // Slave error
        RESP_DECERR     = 2'b11     // Decode error
    } axi4l_resp_t;

    logic clk = 1'b0;
    logic rst = 1'b0;

    logic [31:0] wdata;
    logic wready;
    logic wvalid;

    logic [1:0] bresp;
    logic bvalid;
    logic bready;

    logic [31:0] reg_data;

    axi4l_resp_t wr_resp;

    // Clock and reset
    clocking cb @(posedge clk);
        output rst, wdata, wvalid, bready;
        input wready, bresp, bvalid;
    endclocking

    initial begin
        forever begin
            #5ns;
            clk = ~clk;
        end
    end

    initial begin
        rst = 1'b1;
        repeat (10) @(cb);
        rst = 1'b0;
        $fflush;
    end

    initial begin
        // Init master signals
        bready = 1'b0;
        wvalid = 1'b0;
        $display("Simulation started");
        @(negedge rst);
        $display("Reset deasserted");
        // Let reset propagate if needed
        repeat(10) @(cb);

        // Do one write which should block until done
        write($random, wr_resp);
        $display("Write complete: %s", wr_resp.name());

        $finish;
    end

    task write(logic [31:0] data, resp);
        wdata = data;
        wvalid = 1'b1;
        wait(wvalid && wready);
        @(cb);
        wvalid = 1'b0;
        wait(bvalid);
        @(cb);
        bready = 1'b1;
        wait(bvalid && bready);
        @(cb);
        resp = bresp;
    endtask

    dut //#(
    //)
    dut_i0 (
        .clk        (clk),
        .rst        (rst),
        .wdata	    (wdata),
        .wvalid	    (wvalid),
        .wready	    (wready),
        .bresp      (bresp),
        .bvalid     (bvalid),
        .bready     (bready),
        .reg_data   (reg_data)
    );

endmodule

// Create a small DUT to write a register with an AXI like response (but no address now)
module dut
(
    input   logic           clk,
    input   logic           rst,

    input   logic   [31:0]  wdata,
    input   logic           wvalid,
    output  logic           wready,

    output  logic   [1:0]   bresp,
    output  logic           bvalid,
    input   logic           bready,

    output  logic   [31:0]  reg_data
);   

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            wready      <= 1'b0;

            bvalid      <= 1'b0;
            bresp       <= 2'bXX;

        end else begin
            // End of data beat, start of response beat
            if ( (wready == 1'b1) && (wvalid == 1'b1) ) begin
                wready      <= 1'b0;

                bresp       <= 2'b00;
                bvalid      <= 1'b1;

            // Start of data beat
            end else if ( (wready == 1'b0) && (wvalid == 1'b1) && (bvalid == 1'b0) ) begin
                wready      <= 1'b1;
                reg_data    <= wdata;
            end

            // End of response beat
            if ( (bready == 1'b1) && (bvalid == 1'b1) ) begin
                bvalid      <= 1'b0;
            end
        end
    end

endmodule


