package libman.model;

import java.sql.Date;

/** Thành viên hệ thống: lớp cha của Reader5 và Staff5. */
public class Member5 {
    private Integer id;
    private String username;
    private String password;
    private String fullName;
    private Date birthDate;
    private String email;
    private String phone;
    private String address;
    private String type;
    private boolean active;
    private String note;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public Date getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(Date birthDate) {
        this.birthDate = birthDate;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    /** Vai trò: "Độc giả", "Nhân viên thư viện" hoặc "Nhân viên quản lí". */
    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    /** false = tài khoản bị khóa; với độc giả còn nghĩa là ngừng quyền mượn. */
    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
