package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Reader5;
import libman.model.ReaderCard5;
import libman.model.Status5;
import libman.util.DBUtil;
import libman.util.Html;

public class ReaderCardDAO5 {

    // Một truy vấn lấy cả thẻ lẫn độc giả của thẻ: tblReaderCard5 -> tblReader5 -> tblMember5.
    // c.id đặt bí danh cardId để không trùng với cột m.id (id của thành viên/độc giả).
    private static final String SELECT =
            "SELECT c.id AS cardId, c.cardCode, c.registrationDate, c.expiryDate, c.cardStatus, c.photo, "
            + MemberMapper.MEMBER_COLUMNS + ", r.readerCode "
            + "FROM tblReaderCard5 c "
            + "JOIN tblReader5 r ON r.id = c.readerId "
            + "JOIN tblMember5 m ON m.id = r.id ";

    /** Tìm thẻ theo mã thẻ (quét thẻ), kèm đầy đủ thông tin độc giả; null nếu không có. */
    public ReaderCard5 getCardByCode(String cardCode) throws SQLException {
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE c.cardCode = ?")) {
            ps.setString(1, cardCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /**
     * Tìm thẻ theo mã độc giả, kèm đầy đủ thông tin độc giả. Ưu tiên thẻ đang dùng được,
     * sau đó thẻ có ngày hết hạn muộn nhất; null nếu độc giả chưa có thẻ.
     */
    public ReaderCard5 getCardByReaderCode(String readerCode) throws SQLException {
        String sql = SELECT + "WHERE r.readerCode = ? "
                + "ORDER BY (c.cardStatus = ? AND c.expiryDate >= ?) DESC, c.expiryDate DESC LIMIT 1";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, readerCode);
            ps.setString(2, Status5.ACTIVE);
            ps.setDate(3, Html.today());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /** Đóng gói thẻ trước, sau đó đóng gói độc giả rồi gắn vào thẻ. */
    private static ReaderCard5 map(ResultSet rs) throws SQLException {
        ReaderCard5 card = new ReaderCard5();
        card.setId(rs.getInt("cardId"));
        card.setCardCode(rs.getString("cardCode"));
        card.setRegistrationDate(rs.getDate("registrationDate"));
        card.setExpiryDate(rs.getDate("expiryDate"));
        card.setCardStatus(rs.getString("cardStatus"));
        card.setPhoto(rs.getString("photo"));

        Reader5 reader = new Reader5();
        MemberMapper.fill(reader, rs);                    // id, họ tên, ngày sinh, email, sđt, địa chỉ, is_active
        reader.setReaderCode(rs.getString("readerCode"));
        card.setReader(reader);
        return card;
    }
}
