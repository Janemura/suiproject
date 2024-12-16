module DeFiChallenge::LendingPlatform {

    use sui::transfer;
    use sui::object;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;

    struct Loan {
        id: u64,
        borrower: address,
        lender: address,
        amount: u64,
        collateral: Coin<Balance>,
        interest_rate: u64,
        duration: u64,
        start_time: u64,
    }

    public fun request_loan(
        borrower: address,
        collateral: Coin<Balance>,
        loan_amount: u64,
        interest_rate: u64,
        duration: u64,
        ctx: &mut TxContext
    ): Loan {
        // Generate a unique ID for the loan
        let loan_id = object::new_id(ctx);

        // Initialize the loan struct
        let loan = Loan {
            id: loan_id,
            borrower,
            lender: 0x0, // Placeholder until matched with a lender
            amount: loan_amount,
            collateral,
            interest_rate,
            duration,
            start_time: 0, // Will be set when loan is approved
        };

        // Emit loan request event (optional)
        transfer::emit_event(ctx, loan.clone());

        loan
    }

    public fun approve_loan(
        lender: address,
        loan: Loan,
        ctx: &mut TxContext
    ) {
        // Check if loan is available
        assert!(loan.lender == 0x0, "Loan already approved");

        // Match lender to the loan
        loan.lender = lender;
        loan.start_time = ctx.block_time();

        // Transfer loan amount to borrower
        transfer::transfer_to(loan.borrower, loan.amount, ctx);
    }

    public fun repay_loan(
        loan: Loan,
        repayment_amount: u64,
        ctx: &mut TxContext
    ) {
        // Ensure repayment covers the principal and interest
        let total_due = loan.amount + (loan.amount * loan.interest_rate / 100);
        assert!(repayment_amount >= total_due, "Insufficient repayment");

        // Transfer repayment to lender
        transfer::transfer_to(loan.lender, repayment_amount, ctx);

        // Release collateral to borrower
        transfer::transfer_coin(loan.borrower, loan.collateral, ctx);
    }

    public fun liquidate_loan(
        loan: Loan,
        ctx: &mut TxContext
    ) {
        // Ensure loan is overdue
        let current_time = ctx.block_time();
        assert!(current_time > loan.start_time + loan.duration, "Loan not overdue");

        // Transfer collateral to lender
        transfer::transfer_coin(loan.lender, loan.collateral, ctx);
    }
}
