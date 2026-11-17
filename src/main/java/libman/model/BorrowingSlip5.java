package libman.model;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

/** Phiếu mượn. */
public class BorrowingSlip5 {
    private Integer id;
    private String borrowCode;
    private Date borrowDate;
    private Date dueDate;
    private Reader5 reader;
    private Librarian5 librarian;
    private List<BorrowingDetail5> details = new ArrayList<>();

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getBorrowCode() { return borrowCode; }
    public void setBorrowCode(String borrowCode) { this.borrowCode = borrowCode; }
    public Date getBorrowDate() { return borrowDate; }
    public void setBorrowDate(Date borrowDate) { this.borrowDate = borrowDate; }
    public Date getDueDate() { return dueDate; }
    public void setDueDate(Date dueDate) { this.dueDate = dueDate; }
    public Reader5 getReader() { return reader; }
    public void setReader(Reader5 reader) { this.reader = reader; }
    public Librarian5 getLibrarian() { return librarian; }
    public void setLibrarian(Librarian5 librarian) { this.librarian = librarian; }
    public List<BorrowingDetail5> getDetails() { return details; }
    public void setDetails(List<BorrowingDetail5> details) { this.details = details; }
}
