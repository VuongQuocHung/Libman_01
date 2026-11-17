package libman.model;

import java.sql.Date;

/** Độc giả: kế thừa Member5. */
public class Reader5 extends Member5 {
    private String readerCode;
    private Date registerDate;
    private String readerStatus;

    public String getReaderCode() { return readerCode; }
    public void setReaderCode(String readerCode) { this.readerCode = readerCode; }
    public Date getRegisterDate() { return registerDate; }
    public void setRegisterDate(Date registerDate) { this.registerDate = registerDate; }
    public String getReaderStatus() { return readerStatus; }
    public void setReaderStatus(String readerStatus) { this.readerStatus = readerStatus; }

    public boolean isReaderActive() { return Status5.ACTIVE.equals(readerStatus); }
}
