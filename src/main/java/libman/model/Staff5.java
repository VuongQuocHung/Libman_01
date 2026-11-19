package libman.model;

import java.sql.Date;

/** Nhân viên: kế thừa Member5, là lớp cha của Librarian5 và Manager5. */
public class Staff5 extends Member5 {
    private String staffCode;
    private String position;
    private Date startDate;

    public String getStaffCode() {
        return staffCode;
    }

    public void setStaffCode(String staffCode) {
        this.staffCode = staffCode;
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }

    public Date getStartDate() {
        return startDate;
    }

    public void setStartDate(Date startDate) {
        this.startDate = startDate;
    }
}
