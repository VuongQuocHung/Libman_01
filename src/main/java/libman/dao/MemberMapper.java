package libman.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Member5;

/** Đổ các cột chung của tblMember5 vào đối tượng Member5 (hoặc lớp con). */
final class MemberMapper {
    private MemberMapper() {}

    /** Danh sách cột tblMember5 (bí danh m) dùng chung cho các câu SELECT. */
    static final String MEMBER_COLUMNS =
            "m.id, m.username, m.fullName, m.birthDate, m.email, m.phone, m.address, m.is_active";

    static void fill(Member5 m, ResultSet rs) throws SQLException {
        m.setId(rs.getInt("id"));
        m.setUsername(rs.getString("username"));
        m.setFullName(rs.getString("fullName"));
        m.setBirthDate(rs.getDate("birthDate"));
        m.setEmail(rs.getString("email"));
        m.setPhone(rs.getString("phone"));
        m.setAddress(rs.getString("address"));
        m.setActive(rs.getBoolean("is_active"));
    }
}
