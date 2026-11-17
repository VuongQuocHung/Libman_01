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
    private String accountStatus;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public Date getBirthDate() { return birthDate; }
    public void setBirthDate(Date birthDate) { this.birthDate = birthDate; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getAccountStatus() { return accountStatus; }
    public void setAccountStatus(String accountStatus) { this.accountStatus = accountStatus; }

    public boolean isAccountActive() { return Status5.ACTIVE.equals(accountStatus); }

    /** Chữ cái đầu của tên gọi (từ cuối trong họ tên) để vẽ avatar. */
    public String getInitial() {
        if (fullName == null || fullName.isBlank()) return "?";
        String[] parts = fullName.trim().split("\\s+");
        return parts[parts.length - 1].substring(0, 1).toUpperCase();
    }
}
