-- 채점 10-1-A 대응
-- book 앱 평문 access 로그에서 remote_addr 를 필드로 뽑고(=jq .remote_addr 용),
-- 그 IP 의 서브넷으로 CloudWatch 로그 스트림(AZ 별)을 결정한다.
--   10.0.10.x = private-subnet-a -> /book-svc/ap-northeast-2a
--   10.0.11.x = private-subnet-b -> /book-svc/ap-northeast-2b
-- CRI 파서가 메시지를 log 또는 message 필드에 담을 수 있어 둘 다 확인한다.
function set_az(tag, ts, record)
  local line = record["log"] or record["message"] or ""

  -- remote_addr=IP:port 추출 -> top-level 필드로 저장 (채점 jq 가 읽음)
  local ra = string.match(line, "remote_addr=([^%s]+)")
  if ra ~= nil then
    record["remote_addr"] = ra
  end

  -- IP 추출: remote_addr 우선, 없으면 라인 전체에서 첫 IP
  local ip = nil
  if ra ~= nil then
    ip = string.match(ra, "(%d+%.%d+%.%d+%.%d+)")
  end
  if ip == nil then
    ip = string.match(line, "(%d+%.%d+%.%d+%.%d+)")
  end

  local az = "ap-northeast-2a"
  if ip ~= nil and string.match(ip, "^10%.0%.11%.") then
    az = "ap-northeast-2b"
  end
  record["az_stream"] = "/book-svc/" .. az

  return 2, ts, record
end
